class Reservation < ActiveRecord::Base
  has_many :passengers
  belongs_to :user
  accepts_nested_attributes_for :passengers, :user

  before_save :upcase_confirmation_number

  validates_associated :passengers
  validates :passengers, length: { minimum: 1 }
  validates :confirmation_number, presence: true, length: { is: 6 }
  validates :arrival_city_name, presence: true

  private

  def upcase_confirmation_number
    self.confirmation_number = self.confirmation_number.upcase
  end
end
