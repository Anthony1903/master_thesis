require 'test_helper'

class ContrainteObjectsControllerTest < ActionController::TestCase

    test "index" do

        get :index
        assert_response :success

    end

    test "show" do

        e = default_ensemble("e")
        c = default_contrainte("e")

        e.save
        id = c.save
            
        get :show, :id => id

        assert_response :success

    end

    test "new" do

        get :new
        assert_response :success

    end

    test "create" do

        e = default_ensemble("e")
        e.save

        # Erreurs dans les paramètres 

        contrainte_object = {
          target: '*',
          cond: 'WRONG',
          effet: 'e'
        }

        put :create, :contrainte_object => contrainte_object

        assert_response :success

        # Paramètres ok

        contrainte_object = {
          target: '*',
          cond: 'e',
          effet: 'e'
        }

        put :create, :contrainte_object => contrainte_object

        assert_response :redirect

    end

    test "edit" do

        e = default_ensemble("e")
        c = default_contrainte("e")

        e.save
        id = c.save

        get :edit, :id => id

        assert_response :success

    end

    test "update" do

        e = default_ensemble("e")
        c = default_contrainte("e")

        e.save
        id = c.save

        # Erreurs dans les paramètres 

        contrainte_object = {
          target: '*',
          cond: 'WRONG',
          effet: 'e'
        }

        put :update, :id => id, :contrainte_object => contrainte_object

        assert_response :success

        # Paramètres ok

        contrainte_object = {
          target: '*',
          cond: 'e',
          effet: 'e'
        }

        put :update, :id => id, :contrainte_object => contrainte_object

        assert_response :redirect

    end

    test "destroy" do

        e = default_ensemble("e")
        c = default_contrainte("e")

        e.save
        id = c.save

        get :destroy, :id => id
        assert_response :redirect

    end
  
end
