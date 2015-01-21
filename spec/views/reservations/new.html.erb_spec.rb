require 'rails_helper'

RSpec.describe "reservations/new", :type => :view do
  before(:each) do
    assign(:reservation, Reservation.new(
      :confirmation_number => "MyString",
      :trip_name => "MyString",
      :arrival_city_name => "MyString"
    ))
  end

  it "renders new reservation form" do
    render

    assert_select "form[action=?][method=?]", reservations_path, "post" do
      assert_select "input#reservation_confirmation_number[name=?]", "reservation[confirmation_number]"
    end
  end
end
