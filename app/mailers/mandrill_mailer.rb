class MandrillMailer
  def self.mail(mail = {})
    required! mail, [:to, :template_name, :subject]
    MandrillMailerJob.perform_later(options.merge(mail))
  end

  def self.options
    {
      mandrill_api_key: ENV['MANDRILL_API_KEY'],
      from_name: ENV['MAIL_DEFAULT_FROM_NAME'],
      from_email: ENV['MAIL_DEFAULT_FROM_EMAIL'],
      reply_to: ENV['MAIL_DEFAULT_REPLY_TO'],
      host: ENV['MAIL_DEFAULT_HOST']
    }
  end

  private

  def self.required!(hash, required_keys)
    required_keys.each do |r|
      raise ArgumentError, "`#{r}` is required_keys for #{caller_locations(1,1)[0].label}" unless hash[r].present?
    end
  end
end
