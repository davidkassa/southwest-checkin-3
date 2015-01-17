require 'rails_helper'

RSpec.describe "reservations/index", :type => :view do
  before(:each) do
    assign(:reservations, [
      Reservation.create!(
        :confirmation_number => "Confirmation Number",
        :trip_name => "Trip Name",
        :arrival_city_name => "Arrival City Name"
      ),
      Reservation.create!(
        :confirmation_number => "Confirmation Number",
        :trip_name => "Trip Name",
        :arrival_city_name => "Arrival City Name"
      )
    ])
  end

  it "renders a list of reservations" do
    render
    assert_select "tr>td", :text => "Confirmation Number".to_s, :count => 2
    assert_select "tr>td", :text => "Trip Name".to_s, :count => 2
    assert_select "tr>td", :text => "Arrival City Name".to_s, :count => 2
  end
end
