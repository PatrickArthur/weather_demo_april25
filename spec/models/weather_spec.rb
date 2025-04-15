# spec/models/weather_spec.rb
require 'rails_helper'

RSpec.describe Weather, type: :model do
  let(:api_key) { '8b42b753d9274a5fb02180330251404' }

  before do
    # Stub external API call for each known zipcode
    stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12345")
      .to_return(status: 200, body: '{"location":{"name":"CityName","region":"","country":"US","lat":0,"lon":0},"current":{"temp_c":20}}', headers: {})
      
    stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12211")
      .to_return(status: 200, body: '{"location":{"name":"AnotherCity","region":"","country":"US","lat":0,"lon":0},"current":{"temp_c":25}}', headers: {})
  end
  
  describe 'validations' do
    it 'validates presence of zipcode' do
      weather = Weather.new(zipcode: nil)
      expect(weather.valid?).to be_falsey
      expect(weather.errors[:zipcode]).to include("can't be blank")
    end

    it 'validates uniqueness of zipcode' do
      existing_weather = FactoryBot.create(:weather)
      new_weather = Weather.new(zipcode: existing_weather.zipcode)
      
      expect(new_weather.valid?).to be_falsey
      expect(new_weather.errors[:zipcode]).to include("has already been taken")
    end
  end

  describe 'callbacks' do
    describe 'after_create :fetch_and_store_weather_data' do
      let(:zipcode) { "12345" }
      let(:weather_data) {
        {
          'current' => {
            'temp_c' => 22,
            'condition' => {
              'text' => "Sunny"
            }
          }
        }
      }
      
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch_forecast).and_return(weather_data)
      end

      it 'fetches and stores weather data after creation' do
        weather = FactoryBot.build(:weather, zipcode: zipcode)
        expect(weather.condition).to be_nil

        weather.save!

        expect(weather.reload.temperature).to eq(22)
        expect(weather.reload.condition).to eq("Sunny")
      end

      it 'handles fetching errors gracefully' do
        allow_any_instance_of(WeatherService).to receive(:fetch_forecast).and_return(nil)

        # Attempt to create a Weather record, expecting it to not be saved
        weather = Weather.create(zipcode: '12345')

        # Assert that the weather record doesn't get saved
        expect(weather.persisted?).to be_falsey

        # Confirm the database does not have the weather data
        new_weather = Weather.find_by(zipcode: '12345')
        expect(new_weather).to be_nil
      end
    end
  end
end