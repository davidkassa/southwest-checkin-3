class CheckinJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    puts "Fuu bar!"
  end
end
