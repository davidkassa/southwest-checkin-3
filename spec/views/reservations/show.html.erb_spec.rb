require 'rails_helper'

RSpec.describe "reservations/show", :type => :view do
  before(:each) do
    @reservation = assign(:reservation, Reservation.create!(
      :confirmation_number => "Confirmation Number",
      :trip_name => "Trip Name",
      :arrival_city_name => "Arrival City Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Confirmation Number/)
    expect(rendered).to match(/Trip Name/)
    expect(rendered).to match(/Arrival City Name/)
  end
end
