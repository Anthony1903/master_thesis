require 'test_helper'

class CompositorsControllerTest < ActionController::TestCase
  
    test "should get index" do

        get :index
        assert_response :success

    end

    test "should get show" do

        e = default_ensemble("e")
        id = e.save()

        c = default_cours("c")
        cid = c.save()

        get :show, :sigle => e.sigles
        assert_response :success

        get :show, :sigle => "WRONG"
        assert_response :success

        get :show, :sigle => nil
        assert_response :success

        get :show, :sigle => c.sigles
        assert_response :success

    end

    test "should check" do

        e = default_ensemble("e")
        e2 = default_ensemble("e2")
        e3 = default_ensemble("e3")

        e.contenu = "e2 1 false"
        e2.contenu = "e3 1 false"

        e3.save()
        e2.save()
        e.save()

        get :show, :sigle => e.sigles

        get :check
        assert_response :success

        get :check, :selected_q1 => ["e3 e2"]
        assert_response :success

    end

end
