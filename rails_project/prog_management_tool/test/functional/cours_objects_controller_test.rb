require 'test_helper'

class CoursObjectsControllerTest < ActionController::TestCase

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

        c = default_cours("c")
        id = c.save()

        get :show, :id => id

        assert_response :success

    end

    test "new" do

        get :new
        assert_response :success

    end

    test "create" do

        # Erreurs dans les paramètres 

        cours_object = {
          creditsMax: '-1',
          dureeCours: '30',
          dureeTP: '30',
          professeur: '',
          quadri: '1',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '',
          langue: 'fr-angl',
          creditsMin: '5',
          status: 'actuel'
        }

        put :create, :cours_object => cours_object

        assert_response :success

        # Paramètres ok

        cours_object = {
          creditsMax: '5',
          dureeCours: '30',
          dureeTP: '30',
          professeur: '',
          quadri: '1',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '',
          langue: 'fr-angl',
          creditsMin: '5',
          status: 'actuel'
        }

        put :create, :cours_object => cours_object

        assert_response :redirect

    end

    test "edit" do

        c = default_cours("c")
        id = c.save()

        get :edit, :id => id

        assert_response :success

    end

    test "update" do

        c = default_cours("c")
        id = c.save()

        # Erreurs dans les paramètres 

        cours_object = {
          creditsMax: '-1',
          dureeCours: '30',
          dureeTP: '30',
          professeur: '',
          quadri: '1',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          creditsMin: '5',
          status: 'actuel'
        }

        put :update, :id => id, :cours_object => cours_object

        assert_response :success

        # Paramètres ok

        cours_object = {
          creditsMax: '5',
          dureeCours: '30',
          dureeTP: '30',
          professeur: '',
          quadri: '1',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          creditsMin: '5',
          status: 'actuel'
        }

        put :update, :id => id, :cours_object => cours_object

        assert_response :redirect

    end

    test "destroy" do

        e = default_ensemble("e")
        e.contenu = "c 1 false"
        c = default_cours("c")

        cid = c.save()
        eid = e.save()

        get :destroy, :id => cid
        assert_response :redirect

        get :destroy, :id => eid
        assert_response :redirect

    end
  
end
