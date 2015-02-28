require 'rails_helper'

RSpec.describe User, :type => :model do
 fixtures :reservations, :flights, :passengers, :airports
 let(:user) { User.create(email: 'fuu.bar@baz.com', password: 'password') }

 before do
  user.reservations << reservations(:denver)
  user.save

 end

 it { expect { user.destroy }.to change(Reservation, :count).by(-1) }
end
