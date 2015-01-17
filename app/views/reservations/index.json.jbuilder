json.array!(@reservations) do |reservation|
  json.extract! reservation, :id, :confirmation_number, :trip_name, :arrival_city_name
  json.url reservation_url(reservation, format: :json)
end
