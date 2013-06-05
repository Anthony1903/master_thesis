require 'test_helper'

class PagesControllerTest < ActionController::TestCase

	test "home" do

		get :home

		assert_response :success

	end

end
