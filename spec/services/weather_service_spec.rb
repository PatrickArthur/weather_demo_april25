require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WeatherService do
  let(:zip) { '12345' }
  let(:api_key) { '8b42b753d9274a5fb02180330251404' }
  let(:base_url) { "http://api.weatherapi.com/v1/current.json" }
  let(:response_body) { { "location" => {}, "current" => {} }.to_json }

  before do
    # Stub environment variable for the API key
    allow(ENV).to receive(:[]).with('WEATHER_API_KEY').and_return(api_key)

    # Disable all external network connections except for localhost
    WebMock.disable_net_connect!(allow_localhost: true)

    # Setup WebMock to intercept the HTTP request with appropriate query parameters
    stub_request(:get, base_url)
      .with(
        query: { key: api_key, q: zip },
        headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip, deflate',
          'User-Agent'=>'Ruby'
        })
      .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
  end

  subject { WeatherService.new(zip) }

  describe 'fetching weather data with caching' do
    it 'retrieves fresh data if cache is not available' do
      # Ensure cache is initially empty
      expect(subject.cached?).to be_falsey

      # Call the fetch_forecast method to initiate a network call and cache the response
      result = subject.fetch_forecast

      # Validate the fetched data
      expect(result).to eq(JSON.parse(response_body))

      # Now, check if the data has been cached
      expect(subject.cached?).to be_truthy
    end

    it 'uses cached forecast data if available' do
      # Simulate caching some data
      Rails.cache.write(zip, JSON.parse(response_body))

      # Confirm cache contains data
      expect(subject.cached?).to be_truthy

      # Fetch forecast data, should retrieve from cache without network call
      result = subject.fetch_forecast

      # Verify the result matches cached response
      expect(result).to eq(JSON.parse(response_body))

      # Ensure no network call was made due to the presence of a cache
      expect(WebMock).not_to have_requested(:get, base_url)
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
       # Stubs the environment variable for the API key
       allow(ENV).to receive(:[]).with('WEATHER_API_KEY').and_return(api_key)

       # Stubs the external HTTP request
       stub_request(:get, "#{base_url}?key=#{api_key}&q=#{zip}")
         .with(
           headers: {
             'Accept'=>'*/*',
             'Accept-Encoding'=>'gzip, deflate',
             'User-Agent'=>'Ruby'
           })
         .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
     end

     it 'fetches weather data' do
       response = HTTParty.get("#{base_url}?key=#{api_key}&q=#{zip}")
       expect(response.parsed_response['location']['name']).to eq('City Name')
       expect(response.parsed_response['current']['temp_c']).to eq(20.0)
     end
   end