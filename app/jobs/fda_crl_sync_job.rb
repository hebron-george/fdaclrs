class FdaCrlSyncJob
  include Sidekiq::Job

  BATCH_SIZE = 1000

  def perform
    client = OpenFdaApi::Client.new(api_key: ENV["OPEN_FDA_API_KEY"])
    transparency = client.transparency

    new_ids = []
    skip = 0

    loop do
      response = transparency.complete_response_letters(limit: BATCH_SIZE, skip: skip)
      results = response["results"]
      break if results.blank?

      records = results.map { |r| map_record(r) }
      existing_numbers = CompleteResponseLetter
        .where(application_number: records.flat_map { |r| r[:application_number] }.compact)
        .pluck(:application_number)
        .to_set

      new_ids += records
        .reject { |r| existing_numbers.include?(r[:application_number]) }
        .map { |r| r[:application_number] }

      CompleteResponseLetter.upsert_all(
        records,
        unique_by: :application_number,
        update_only: %i[
          letter_type letter_date company_name company_rep company_address
          approver_name approver_title approver_center file_name text
        ]
      )

      total = response.dig("meta", "results", "total").to_i
      skip += results.size
      break if skip >= total
    end

    SystemSetting.set("last_crl_sync_at", Time.current.iso8601)
    Rails.logger.info "[FdaCrlSyncJob] Sync complete. #{new_ids.size} new record(s)."

    new_ids
  end

  private

  def map_record(result)
    now = Time.current

    {
      application_number: result["application_number"],
      letter_type:        result["letter_type"],
      letter_date:        result["letter_date"],
      company_name:       result["company_name"],
      company_rep:        result["company_rep"],
      company_address:    result["company_address"],
      approver_name:      result["approver_name"],
      approver_title:     result["approver_title"],
      approver_center:    result["approver_center"],
      file_name:          result["file_name"],
      text:               result["text"],
      created_at:         now,
      updated_at:         now
    }
  end
end
