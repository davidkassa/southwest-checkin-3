class CheckinMailerPreview < ActionMailer::Preview
  def successful_checkin
    CheckinMailer.successful_checkin(Checkin.completed.first)
  end
end
