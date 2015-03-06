require "rails_helper"

RSpec.describe UserMailer, :type => :mailer do
  let(:user) { User.create(email: "fuu.bar.@baz.com", password: "password") }

  it 'renders the email' do
    expect { UserMailer.welcome(user.email).deliver_now }.to_not raise_error
  end
end
