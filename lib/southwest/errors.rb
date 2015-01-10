module Southwest
  SouthwestError = Class.new(StandardError)
  InvalidCredentialsError = Class.new(SouthwestError)
  RequestError = Class.new(SouthwestError)
end
