module ApplicationHelper
  def google_tag_manager?
    Rails.env.production? && ENV['GOOGLE_TAG_MANAGER_ENABLED']
  end
end
