# Provides an API for canceling a job
# that supports ActiveJob::QueueAdapters::SidekiqAdapter.
#
# NOTE: `Sidekiq::ScheduledSet` does not provide a test adapter.
# It works directly with Redis, so be aware that **there is no
# protection against mutating your redis store**.
#
# This does not support `ActiveJob::QueueAdapters::TestAdapter`. The
# test adapter doesn't (yet) support `job_id` in the in-memory store:
#
# https://github.com/rails/rails/blob/c9a4c2a5ce3eab52e2335362fe643328831a0ac4/activejob/lib/active_job/queue_adapters/test_adapter.rb#L18
#
# Usage:
#
#   class ExampleJob << ActiveJob::Base
#     extend Cancelable
#   end
#
#   ExampleJob.cancel("9b270abb-4dac-4c8a-bb9e-95b03f63b5c8")
#
module Cancelable
  # Cancel a scheduled job. Beware that this is O(n) lookup,
  # so it will not be performant with a large number of jobs.
  def cancel(active_job_id)
    if ActiveJob::Base.queue_adapter == ActiveJob::QueueAdapters::SidekiqAdapter
      cancel_sidekiq_job(active_job_id)
    end
  end

  private

  def cancel_sidekiq_job(active_job_id)
    r = Sidekiq::ScheduledSet.new
    r.each do |sorted_entry|
      if sorted_entry["args"].first["job_id"] == active_job_id
        sorted_entry.delete
        break
      end
    end
  end
end
