module SouthwestCheckin
  SouthwestCheckinError = Class.new(StandardError)
  AirportNotFound = Class.new(ActiveRecord::RecordNotFound)
  FailedCheckin = Class.new(SouthwestCheckinError)
end
