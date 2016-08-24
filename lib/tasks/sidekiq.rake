require "sidekiq/api"

namespace :sidekiq do
  desc "Check if there are any scheduled that should have already been run, if so fire up sidekiq"
  task :process_scheduled do
    # sidekiq is already running, don't need to run
    if Sidekiq::ProcessSet.new.size == 0
      ss = Sidekiq::ScheduledSet.new
      if ss.first.try { |job| job.at < Time.now }
        exec "bundle exec sidekiq"
      end
    end
  end
end