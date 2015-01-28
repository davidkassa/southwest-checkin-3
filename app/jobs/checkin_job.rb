class CheckinJob < ActiveJob::Base
  queue_as :checkin

  def perform(*args)
    puts "Fuu bar!"
  end
end
