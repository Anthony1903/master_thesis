require 'test_helper'

class EnsembleObjectsControllerTest < ActionController::TestCase

    test "index" do

        get :index
        assert_response :success

        get :index, :status => "actuel", :critere => "sigle", :valeur => "S"
        assert_response :success

    end

    test "restricted_index" do

        get :restricted_index, :status => "actuel", :critere => "sigle", :valeur => "S"
        assert_response :redirect

        get :restricted_index, :status => "tous"
        assert_response :redirect

    end

    test "show" do

        e = default_ensemble("e")
        id = e.save()
          
        get :show, :id => id

        assert_response :success

    end

    test "new" do

        get :new
        assert_response :success

    end

    test "create" do

    # Erreurs dans les paramètres 

        ensemble_object = {
          creditsMax: '-1',
          creditsMin: '0',
          contenu: '',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        put :create, :ensemble_object => ensemble_object

        assert_response :success

        # Paramètres ok

        ensemble_object = {
          creditsMax: '5',
          creditsMin: '0',
          contenu: '',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        put :create, :ensemble_object => ensemble_object

        assert_response :redirect

    end

    test "edit" do

        e = default_ensemble("e")
        id = e.save()

        get :edit, :id => id

        assert_response :success

    end

    test "update" do

        e = default_ensemble("e")
        id = e.save()

        # Erreurs dans les paramètres 

        ensemble_object = {
          creditsMax: '-1',
          creditsMin: '0',
          contenu: '',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        put :update, :id => id, :ensemble_object => ensemble_object

        assert_response :success

        # Paramètres ok

        ensemble_object = {
          creditsMax: '5',
          creditsMin: '0',
          contenu: '',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        put :update, :id => id, :ensemble_object => ensemble_object

        assert_response :redirect

    end

    test "compaire" do
        
        e = default_ensemble("e")
        e2 = default_ensemble("e2")

        e.save()
        e2.save()

        get :compaire, :sigle => "Wrong"
        assert_response :success    

        get :compaire, :sigle2 => "Wrong"
        assert_response :success    

        get :compaire, :sigle => "e"
        assert_response :success    

        get :compaire, :sigle => "e2"
        assert_response :success    

        get :compaire, :sigle => "e", :sigle2 => "e2"
        assert_response :success    

    end

    test "destroy" do

        e = default_ensemble("e")
        e.contenu = "e2 1 false"
        e2 = default_ensemble("e2")

        id2 = e2.save()
        id = e.save()

        get :destroy, :id => id2
        assert_response :redirect

        get :destroy, :id => id, :recursively => "true"
        assert_response :redirect

    end

end
