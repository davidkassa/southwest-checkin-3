require_relative '../../lib/southwest/errors'

class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]
  rescue_from Southwest::RequestError, with: :southwest_request_error, only: :create

  respond_to :html

  def index
    @reservations = current_user.reservations.all
    respond_with(@reservations)
  end

  def show
    respond_with(@reservation)
  end

  def new
    @reservation = Reservation.new
    respond_with(@reservation)
  end

  def edit
  end

  def create
    @reservation = current_user.reservations.new(reservation_params)
    @reservation.save
    respond_with(@reservation)
  end

  def update
    @reservation.update(reservation_params)
    respond_with(@reservation)
  end

  def destroy
    @reservation.destroy
    respond_with(@reservation)
  end

  private

  def southwest_request_error
    flash[:notice] = 'Sorry! There was an error communicating with Southwest. This has been reported. Please try to add your flight later.'
    respond_with(@reservation)
  end

  def set_reservation
    @reservation = Reservation.includes({ flights: [{ flight_checkins: [:passenger] }, :departure_airport, :arrival_airport] }, :passengers).find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:confirmation_number, :first_name, :last_name)
  end
end
