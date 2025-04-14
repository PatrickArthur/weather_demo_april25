class WeatherService
  def initialize(zip)
    @zip = zip
    @api_key = ENV['WEATHER_API_KEY']
    @base_url = "http://api.weatherapi.com/v1/current.json"
  end

  def fetch_forecast
    Rails.cache.fetch(@zip, expires_in: 30.minutes) do
      response = HTTParty.get("#{@base_url}?key=#{@api_key}&q=#{@zip}")
      if response.success?
        response.parsed_response
      else
        nil
      end
    end
  end

  def cached?
    Rails.cache.exist?(@zip)
  end
end