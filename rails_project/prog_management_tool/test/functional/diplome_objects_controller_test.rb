require 'test_helper'

class DiplomeObjectsControllerTest < ActionController::TestCase

    test "index" do

        get :index
        assert_response :success

    end

    test "show" do

        e = default_ensemble("e")
        d = default_diplome("e")

        e.save
        id = d.save
          
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

        diplome_object = {
          cycle: 'WRONG',
          sigle: 's',
          facSigle: 'fs',
          root_sigle: 'e'
        }

        put :create, :diplome_object => diplome_object

        assert_response :success

        # Paramètres ok

        diplome_object = {
          cycle: 'master',
          sigle: 's',
          facSigle: 'fs',
          root_sigle: 'e'
        }

        put :create, :diplome_object => diplome_object

        assert_response :redirect

    end

    test "edit" do

        e = default_ensemble("e")
        d = default_diplome("e")

        e.save
        id = d.save

        get :edit, :id => id

        assert_response :success

    end

    test "update" do

        e = default_ensemble("e")
        d = default_diplome("e")

        e.save
        id = d.save

        # Erreurs dans les paramètres 

        diplome_object = {
          cycle: 'Wrong',
          sigle: 's',
          facSigle: 'fs',
          root_sigle: 'e'
        }

        put :update, :id => id, :diplome_object => diplome_object

        assert_response :success

        # Paramètres ok

        diplome_object = {
          cycle: 'master',
          sigle: 's',
          facSigle: 'fs',
          root_sigle: 'e'
        }

        put :update, :id => id, :diplome_object => diplome_object

        assert_response :redirect

    end

    test "destroy" do

        e = default_ensemble("e")
        d = default_diplome("e")

        e.save
        id = d.save

        get :destroy, :id => id
        assert_response :redirect

    end

end
