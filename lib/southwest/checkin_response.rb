module Southwest
  class CheckinResponse
    attr_reader :flight_checkin_new
    attr_reader :get_all_boarding_passes
    attr_reader :view_boarding_passes

    def initialize(flight_checkin_new:,
                   get_all_boarding_passes:,
                   view_boarding_passes:)
      @flight_checkin_new      = flight_checkin_new
      @get_all_boarding_passes = get_all_boarding_passes
      @view_boarding_passes    = view_boarding_passes
    end

    def flight_information
      flight_checkin_new.body['output']
    end

    def boarding_pass_details
      get_all_boarding_passes.body['mbpDetails']
    end

    def checkin_details
      get_all_boarding_passes.body['mbpPassenger']
    end
  end
end
