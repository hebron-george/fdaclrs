class FdaCrlSyncJob
  include Sidekiq::Job

  BATCH_SIZE = 1000

  def perform
    client = OpenFdaApi::Client.new(api_key: ENV["OPEN_FDA_API_KEY"])
    transparency = client.transparency

    new_file_names = []
    skip = 0

    loop do
      response = transparency.complete_response_letters(limit: BATCH_SIZE, skip: skip)
      results = response["results"]
      break if results.blank?

      records = results.filter_map { |r| map_record(r) }
                       .index_by { |r| r[:file_name] }
                       .values

      existing_file_names = CompleteResponseLetter
        .where(file_name: records.map { |r| r[:file_name] })
        .pluck(:file_name)
        .to_set

      new_file_names += records
        .reject { |r| existing_file_names.include?(r[:file_name]) }
        .map { |r| r[:file_name] }

      CompleteResponseLetter.upsert_all(
        records,
        unique_by: :file_name,
        update_only: %i[
          application_numbers letter_type letter_date company_name company_rep
          company_address approver_name approver_title approver_center text
        ]
      )

      total = response.dig("meta", "results", "total").to_i
      skip += results.size
      break if skip >= total
    end

    SystemSetting.set("last_crl_sync_at", Time.current.iso8601)
    Rails.logger.info "[FdaCrlSyncJob] Sync complete. #{new_file_names.size} new record(s)."

    new_file_names
  end

  private

  def map_record(result)
    file_name = result["file_name"]
    return nil if file_name.blank?

    now = Time.current

    {
      file_name:           file_name,
      application_numbers: Array(result["application_number"]).compact,
      letter_type:         result["letter_type"],
      letter_date:         result["letter_date"],
      company_name:        result["company_name"],
      company_rep:         result["company_rep"],
      company_address:     result["company_address"],
      approver_name:       result["approver_name"],
      approver_title:      result["approver_title"],
      approver_center:     result["approver_center"],
      text:                result["text"],
      created_at:          now,
      updated_at:          now
    }
  end
end
