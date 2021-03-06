class UserTripsController < ApplicationController
  def create
    @request = UserTrip.new(user_trip_params)
    @request.user = current_user
    @trip = Trip.find(params[:trip_id])
    @request.trip = @trip

    if @trip.user == current_user
      redirect_to trip_path(@trip)
      flash[:alert] = "C'est ta propre sortie, boloss."
    else
      @request.state = "demandé"
      if @request.save!
        redirect_to trip_messages_path(@trip)
        flash[:notice] = "Demande envoyée. Prenez une bière et détendez-vous."
      end
    end
  end

  def accept
    @request = UserTrip.find(params[:id])
    if @request.update!(state: "accepté")
      redirect_to my_trips_path
      flash[:notice] = "Copain validé!"
    end
  end

  def decline
    @request = UserTrip.find(params[:id])
    if @request.update!(state: "refusé")
      redirect_to my_trips_path
      flash[:notice] = "Copain refusé!"
    end
  end

  private

  def user_trip_params
    params.require(:user_trip).permit(:default_message)
  end
end
