class ExampleJob
  include Sidekiq::Job

  def perform
    Rails.logger.info "ExampleJob ran at #{Time.current}"
  end
end
