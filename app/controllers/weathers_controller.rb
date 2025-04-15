class WeathersController < ApplicationController
  def index
    @weathers = Weather.order(created_at: :desc).limit(20)
  end

  def new
    @weather = Weather.new
  end

  def edit
    @weather = Weather.find(params[:id])
    rescue ActiveRecord::RecordNotFound
     redirect_to weathers_path, notice: "Weather not found."
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

  def update
    @weather = Weather.find(params[:id])

    if @weather.update(weather_params)
      redirect_to weathers_path, notice: 'Weather data updated successfully.'
    else
      flash.now[:alert] = 'Weather update failed.'
      render :edit
    end
  end

  def destroy
    @weather = Weather.find(params[:id])

    if @weather.destroy
      redirect_to weathers_path, notice: 'Weather data deleted successfully.'
    else
      redirect_to weathers_path, alert: 'Weather deletion failed.'
    end
  end

  private

  def weather_params
    params.require(:weather).permit(:zipcode) # Adjust according to your model's attributes
  end
end