namespace :fda do
  namespace :crl do
    desc "Sync FDA Complete Response Letters from the openFDA API"
    task sync: :environment do
      puts "Starting FDA CRL sync..."
      new_ids = FdaCrlSyncJob.new.perform
      puts "Done. #{new_ids.size} new record(s) added."
    end

    desc "Enqueue summary generation for letters that have OCR text but no summary (pass FORCE=1 to regenerate all)"
    task summarize: :environment do
      force = ENV["FORCE"].present?
      scope = CompleteResponseLetter.where.not(text: [nil, ""])
      scope = scope.where(summary: nil) unless force

      ids = scope.pluck(:id)
      ids.each { |id| GenerateLetterSummaryJob.perform_async(id, force) }
      puts "Enqueued #{ids.size} summary job(s)#{" (forced regeneration)" if force}."
    end
  end
end
