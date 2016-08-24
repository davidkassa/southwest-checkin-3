json.array!(@reservations) do |reservation|
  json.extract! reservation, :id, :confirmation_number
  json.url reservation_url(reservation, format: :json)
end
