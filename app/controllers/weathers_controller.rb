class WeathersController < ApplicationController
  def index
    @weathers = Weather.order(created_at: :desc).limit(20)
  end

  def new
    @weather = Weather.new
  end

  def create
    @weather = Weather.new(weather_params)

    if @weather.save
      redirect_to weathers_path, notice: 'Weather data fetched and stored successfully.'
    else
      flash.now[:alert] = 'Weather creation failed.'
      render :new
    end
  end

  private

  def weather_params
    params.require(:weather).permit(:zipcode) # Adjust according to your model's attributes
  end
end