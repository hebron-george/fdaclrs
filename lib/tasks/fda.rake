namespace :fda do
  namespace :crl do
    desc "Sync FDA Complete Response Letters from the openFDA API"
    task sync: :environment do
      puts "Starting FDA CRL sync..."
      new_ids = FdaCrlSyncJob.new.perform
      puts "Done. #{new_ids.size} new record(s) added."
    end
  end
end
