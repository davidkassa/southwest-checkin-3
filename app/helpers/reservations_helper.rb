module ReservationsHelper
  def flight_time(local_time)
    time_tag local_time, local_time.strftime('%l:%M %p %Z')
  end

  def flight_date(local_time)
    time_tag local_time, local_time.strftime('%a, %b %d')
  end

  def flight_time_basic(local_time)
    time_tag local_time, local_time.strftime('%l:%M %p')
  end
end
