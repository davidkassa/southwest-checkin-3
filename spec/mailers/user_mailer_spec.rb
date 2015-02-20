require "rails_helper"

RSpec.describe UserMailer, :type => :mailer do
  describe '#welcome_email' do
    let(:user) { User.create(email: 'fuu.bar@baz.com', password: 'password') }
    subject { UserMailer.welcome_email(user) }

    it {
      perform_enqueued_jobs do
        result = subject
        expect(result.message[:subject]).to match(/Welcome to/)
        expect(result.message[:to][0][:email]).to eql('fuu.bar@baz.com')
      end
    }
  end
end
