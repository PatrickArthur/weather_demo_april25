# spec/controllers/weathers_controller_spec.rb
require 'rails_helper'

RSpec.describe WeathersController, type: :controller do
  let(:api_key) { '8b42b753d9274a5fb02180330251404' }

  before do
    # Stub external API call for each known zipcode
    stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12345")
      .to_return(status: 200, body: '{"location":{"name":"CityName","region":"","country":"US","lat":0,"lon":0},"current":{"temp_c":20}}', headers: {})
      
    stub_request(:get, "http://api.weatherapi.com/v1/current.json?key=#{api_key}&q=12211")
      .to_return(status: 200, body: '{"location":{"name":"AnotherCity","region":"","country":"US","lat":0,"lon":0},"current":{"temp_c":25}}', headers: {})
  end

  describe "GET #index" do
    it "assigns @weathers" do
      weather1 = FactoryBot.create(:weather, zipcode: "12345")
      weather2 = FactoryBot.create(:weather, zipcode: "12211")
      get :index
      expect(assigns(:weathers)).to match_array([weather1, weather2])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "GET #new" do
    it "assigns a new Weather to @weather" do
      get :new
      expect(assigns(:weather)).to be_a_new(Weather)
    end

    it "renders the new template" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates a new weather" do
        expect {
          post :create, params: { weather: FactoryBot.attributes_for(:weather) }
        }.to change(Weather, :count).by(1)
      end

      it "redirects to the index path with a notice" do
        post :create, params: { weather: FactoryBot.attributes_for(:weather) }
        expect(response).to redirect_to(weathers_path)
        expect(flash[:notice]).to eq('Weather data fetched and stored successfully.')
      end
    end

    context "with invalid attributes" do
      it "does not save the new weather" do
        expect {
          post :create, params: { weather: FactoryBot.attributes_for(:weather, zipcode: nil) }
        }.not_to change(Weather, :count)
      end

      it "re-renders the new template" do
        post :create, params: { weather: FactoryBot.attributes_for(:weather, zipcode: nil) }
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq('Weather creation failed.')
      end
    end
  end
end