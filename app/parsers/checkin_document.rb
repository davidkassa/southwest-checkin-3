class CheckinDocument
  attr_reader :document_json

  def initialize(document_json)
    @document_json = document_json
  end

  def checkin_for?(full_name_2, flight_number_2)
    flight_number == flight_number_2 &&
    full_name =~ /#{full_name_2}/i
  end

  def flight_number
    document_json['flight_num']
  end

  def full_name
    document_json['name']
  end

  # Documents return each digit of the boarding position
  # as seperate fields with variable names. This extracts each
  # digit in order and maps them to one final value.
  #
  # Hard to believe, I know.
  def boarding_position
    ordered_positions.inject('') { |final,p| final + p[1] }
  end

  def boarding_group
    document_json["boardingroup_text"]
  end

  def confirmation_number
    document_json['pnr']
  end

  private

  def ordered_positions
    document_json.select { |k,v| k =~ /position[0-9]_text/ }.sort_by { |h| h[0] }
  end
end
