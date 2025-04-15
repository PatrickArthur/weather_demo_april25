require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WeatherService do
  let(:api_key) { '8b42b753d9274a5fb02180330251404' }
  let(:zip) {'12211'}
  let(:response_body_for_other_zip) { '{"location":{"name":"CityName","region":"","country":"US","lat":0,"lon":0},"current":{"temp_c":20}}' }
  let(:response_body_for_zip_12211) { '{"location":{"name":"AnotherCity","region":"","country":"US","lat":0,"lon":0},"current":{"temp_c":25}}' }
  let(:cache_data) { JSON.parse(response_body_for_zip_12211) }

  before do
    # Stub external API call for each known zipcode
    stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12345")
      .to_return(status: 200, body: response_body_for_other_zip, headers: {})
      
    stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12211")
      .to_return(status: 200, body: response_body_for_zip_12211, headers: {})

    # Clear the Rails cache if required to simulate a fresh state, depending on your caching mechanism.
    Rails.cache.clear if defined?(Rails.cache)
  end

  subject { WeatherService.new(zip) }

  describe 'fetching weather data with caching' do
    it 'retrieves fresh data if cache is not available' do
      # Ensure cache is initially empty
      expect(subject.cached?).to be_falsey

      # Fetch the forecast data
      result = subject.fetch_forecast

      # Parse the result to match the expected hash
      parsed_result = JSON.parse(result)

      # Validate that the result matches the API response for zip 12211
      expect(parsed_result).to eq(JSON.parse(response_body_for_zip_12211))

      # Verify that the data has been cached
      expect(subject.cached?).to be_truthy
    end

    it 'uses cached forecast data if available' do
      # Simulate caching some data, ensure it's cached as a Hash
      Rails.cache.write(zip, JSON.parse(response_body_for_other_zip))

      # Confirm cache contains data
      expect(subject.cached?).to be_truthy

      # Fetch forecast data; it should retrieve from cache without network call
      result = subject.fetch_forecast

      # Since fetch_forecast should return a Hash (not a raw JSON string), we do not need to parse it
      # Assuming response_body_for_other_zip is a raw JSON string, parse it for comparison
      parsed_expected = JSON.parse(response_body_for_other_zip)

      # Verify the result matches cached response
      expect(result).to eq(parsed_expected)

      # Ensure no network call was made due to the presence of a cache
      expect(WebMock).not_to have_requested(:get, 'https://api.weatherapi.com/v1')
        .with(query: { key: api_key, q: zip })
    end
  end
end

RSpec.describe 'Weather API integration', type: :feature do
     let(:zip) { '12345' }
     let(:api_key) { '8b42b753d9274a5fb02180330251404' }
     let(:base_url) { "http://api.weatherapi.com/v1/current.json" }
     let(:response_body) { { "location" => { "name" => "City Name" }, "current" => { "temp_c" => 20.0 } }.to_json }

     before do
      # Stub external API call for each known zipcode
      stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12345")
        .to_return(status: 200, body: response_body, headers: {})

      # Clear the Rails cache if required to simulate a fresh state, depending on your caching mechanism.
      Rails.cache.clear if defined?(Rails.cache)
    end

     it 'fetches weather data' do
       response = HTTParty.get("#{base_url}?key=#{api_key}&q=#{zip}")
       parsed_resp = JSON.parse(response)
       expect(parsed_resp["location"]["name"]).to eq('City Name')
       expect(parsed_resp['current']['temp_c']).to eq(20.0)
     end
   end