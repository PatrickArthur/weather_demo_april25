require "test_helper"

class WeathersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get weathers_index_url
    assert_response :success
  end
end
