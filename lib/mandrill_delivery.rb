require 'mandrill'

class MandrillDelivery
  attr_reader :mail
  attr_reader :message

  def initialize(mail)
    @mail = mail
  end

  def deliver!(mail)
    build_message
    send_message
  end

  def build_message
    @message = {
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

    true
  end

  def send_message
    m = Mandrill::API.new(ENV['MANDRILL_API_KEY'])
    m.messages.send_template(template_name, template_content, message)
  end

  def template_name
    mail[:template_name]
  end

  def template_content
    mail[:template_content] || []
  end
end
