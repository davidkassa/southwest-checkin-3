module Southwest
  SouthwestError = Class.new(StandardError)
  InvalidCredentialsError = Class.new(SouthwestError)
end
