Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = ENV['SIDEKIQ_POLLING_INTERVAL'].present? ? ENV['SIDEKIQ_POLLING_INTERVAL'].to_i : 1
end
