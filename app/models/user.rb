class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :lockable

  has_many :reservations, dependent: :destroy
  after_commit :send_welcome_email, on: :create

  private

  def send_welcome_email
    UserMailer.welcome(self.email).deliver_later
  end
end
