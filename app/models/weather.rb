class Weather < ApplicationRecord
  validates :zipcode, presence: true, uniqueness: true

  # Ensures fetching data is placed within a rescue block
  after_create :fetch_and_store_weather_data

  private

  def fetch_and_store_weather_data
    weather_service = WeatherService.new(zipcode)
    
    begin
      forecast_data = weather_service.fetch_forecast

      if forecast_data && forecast_data['current']
        update!(
          temperature: forecast_data['current']['temp_c'],
          condition: forecast_data['current']['condition']['text']
        )
      else
        raise ActiveRecord::Rollback, "No forecast data found"
      end

    rescue StandardError => e
      Rails.logger.error("Weather update failed: #{e.message}")
      raise ActiveRecord::Rollback
    end
  end
end