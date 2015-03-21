# Southwest::CheckinErrorResponse is a duck type of Southwest::CheckinResponse
# that is meant to communicate a failed checkin. It contains additional methods
# for checking things like `cancelled_reservation?`.
module Southwest
  class CheckinErrorResponse
    attr_reader :flight_checkin_new
    attr_reader :get_all_boarding_passes
    attr_reader :view_boarding_passes
    attr_reader :error

    def initialize(error:,
                   flight_checkin_new: nil,
                   get_all_boarding_passes: nil,
                   view_boarding_passes: nil)
      @error                   = error
      @flight_checkin_new      = flight_checkin_new
      @get_all_boarding_passes = get_all_boarding_passes
      @view_boarding_passes    = view_boarding_passes
    end

    def error?
      true
    end

    def incorrect_passenger?
      error =~ /passenger name entered does not match/
    end

    def cancelled_reservation?
      flight_checkin_new && !!(flight_checkin_new.body["errmsg"] =~ /cancelled/i)
    end

    def flight_information
      nil
    end

    def single_passenger_details
      nil
    end

    def single_passenger_documents
      nil
    end
  end
end
