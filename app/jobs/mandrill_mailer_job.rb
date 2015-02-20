class MandrillMailerJob < ActiveJob::Base
  queue_as :mail

  attr_reader :mail
  attr_reader :message

  def perform(mail)
    mandrill_mail(mail)
  end

  protected

  def mandrill_mail(mail)
    @mail = mail
    @message = build_message
    send_message
  end

  def build_message
    {
      subject: mail[:subject],
      from_name: mail[:from_name],
      from_email: mail[:from_email],
      headers: {
        "Reply-To" => mail[:reply_to]
      },
      metadata: {
        website: mail[:host]
      },
      to: [
        {
          email: mail[:to],
          type: 'to'
        }
      ],
      inline_css: true
    }
  end

  def send_message
    if !Rails.env.test?
      mandrill.messages.send_template(template_name, template_content, message)
    end
  end

  def template_name
    mail[:template_name]
  end

  def template_content
    mail[:template_content] || []
  end

  def mandrill
    @mandrill ||= Mandrill::API.new(ENV['MANDRILL_API_KEY'])
  end
end
