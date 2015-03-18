module Southwest
  class CheckinResponse
    attr_reader :flight_checkin_new
    attr_reader :get_all_boarding_passes
    attr_reader :view_boarding_passes
    attr_reader :error

    def initialize(flight_checkin_new:,
                   get_all_boarding_passes:,
                   view_boarding_passes:)
      @flight_checkin_new      = flight_checkin_new
      @get_all_boarding_passes = get_all_boarding_passes
      @view_boarding_passes    = view_boarding_passes
      @error                   = nil
    end

    def error?
      false
    end

    def flight_information
      flight_checkin_new.body['output']
    end

    def multiple_passengers?
      multiple_passenger_documents.any?
    end

    def missing_passengers?
      multiple_passenger_documents.none? && single_passenger_documents.none?
    end

    def multiple_passenger_documents
      get_all_boarding_passes.body['Document']
    end

    def single_passenger_details
      get_all_boarding_passes.body['mbpDetails']
    end

    def single_passenger_documents
      get_all_boarding_passes.body['mbpPassenger']
    end
  end
end
