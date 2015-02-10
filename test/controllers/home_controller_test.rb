require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  test "unauthenticated user must get index" do
    get :index
    assert_response :success
  end

  test "authenticated user must be redirected to event's page" do
  	sign_in @organizer
  	get :index
  	assert_response :redirect
  	assert_redirected_to controller: "events", action: "index"
  end

end
