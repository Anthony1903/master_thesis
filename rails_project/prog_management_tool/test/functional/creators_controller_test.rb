require 'test_helper'

class CreatorsControllerTest < ActionController::TestCase

    test "index" do

        get :index
        assert_response :success

    end

    test "initialize_tree" do

        c = default_cours("c")
        c.save()

        e = default_ensemble("e")
        e.save()

        get :initialize_tree
        assert_response :success

        get :initialize_tree, :base => "c"
        assert_response :success

        get :initialize_tree, :base => "unknown"
        assert_response :success

        get :initialize_tree, :base => "e"
        assert_response :success

    end

    test "new_module" do

        get :new_module
        assert_response :success

    end

    test "create" do

        e = default_ensemble("root")
        e.save()

        e = default_ensemble("e")
        e.save()

        e2 = default_ensemble("e2")
        e2.save()

        # Création de l'arbre

        get :initialize_tree, :base => "root"
        assert_response :success

        # Cas 1 : Erreur dans les paramètres

        ensemble_object = {
          creditsMax: '-1',
          creditsMin: '0',
          contenu: '',
          sigles: 'e',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        post :create, :ensemble_object => ensemble_object, :annee => "1", :obligatoire => "obligatoire", :type => "new", :sigle => "e", :parent => "root"
        assert_response :success

        # Cas 2 : Paramètres corrects

        ensemble_object = {
          creditsMax: '5',
          creditsMin: '0',
          contenu: '',
          sigles: 'e',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }
        post :create, :ensemble_object => ensemble_object, :annee => "1", :obligatoire => "obligatoire", :type => "new", :sigle => "e", :parent => "root"
        assert_response :success


        # Cas 2 : ajout ensemble existant (erreur)

        post :create, :annee => "1", :obligatoire => "obligatoire", :sigle => "e3", :parent => "root"
        assert_response :success


        # Cas 3 : ajout ensemble existant (ok)

        post :create, :annee => "1", :obligatoire => "obligatoire", :sigle => "e2", :parent => "root"
        assert_response :success

        # Cas 4 : ajout nouvel ensemble en tant que racine

        # Réinitialisation de l'arbre
        get :initialize_tree, :base => "new_root"
        assert_response :success

        ensemble_object = {
          creditsMax: '5',
          creditsMin: '5',
          contenu: '',
          sigles: 'new_root',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        post :create, :ensemble_object => ensemble_object, :type => "new"
        assert_response :success

    end

    test "create, add a loop" do

        e = default_ensemble("e")
        e.save()

        e = default_ensemble("root")
        e.contenu = "e 1 false"
        e.save()

        e2 = default_ensemble("e2")
        e2.contenu = "root 1 false"
        e2.save()

        # Création de l'arbre depuis "root"

        get :initialize_tree, :base => "root"
        assert_response :success

        # Insertion d'une boucle

        post :create, :annee => "1", :obligatoire => "optionnel", :sigle => "e2", :parent => "e"
        assert_response :success

    end

    test "edit_module" do

        e = default_ensemble("e")
        e.save()

        e = default_ensemble("root")
        e.contenu = "e 1 false"
        e.save()

        # Création de l'arbre

        get :initialize_tree, :base => "root"
        assert_response :success

        # Edition noeud inexistant

        get :edit_module, :sigle => "WRONG"
        assert_response :success

        # Edition de la racine

        get :edit_module, :sigle => "root"
        assert_response :success

        # Edition du sous arbre

        get :edit_module, :sigle => "e"
        assert_response :success

    end

    test "update" do

        e = default_ensemble("e")
        e.save()

        e = default_ensemble("root")
        e.contenu = "e 1 false"
        e.save()

        # Création de l'arbre et sélection du noeud sujet à mise à jour

        get :initialize_tree, :base => "root"
        assert_response :success

        get :edit_module, :sigle => "e"
        assert_response :success

        # Manque de paramètres

        get :update
        assert_response :success

        # Mise à jour violant contraintes sur les champs

        ensemble_object = {
          creditsMax: '-1',
          creditsMin: '0',
          contenu: '',
          sigles: 'e',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        get :update, :ensemble_object => ensemble_object, :old_sigle => "e"
        assert_response :success

        # Mise à jour violant d'autres contraintes

        ensemble_object = {
          creditsMax: '100',
          creditsMin: '100',
          contenu: '',
          sigles: 'e',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        get :update, :ensemble_object => ensemble_object, :old_sigle => "e"
        assert_response :success

        # Mise à jour correcte

        ensemble_object = {
          creditsMax: '5',
          creditsMin: '5',
          contenu: '',
          sigles: 's',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        get :update, :ensemble_object => ensemble_object, :old_sigle => "e" 
        assert_response :success

        # Mise à jour correcte incluant le contenu

        ensemble_object = {
          creditsMax: '5',
          creditsMin: '5',
          contenu: 's 2 true',
          sigles: 'root',
          intitule: '',
          dptCharge: '',
          commentaire: '',
          validite: '2000',
          langue: 'fr-angl',
          status: 'actuel'
        }

        get :update, :ensemble_object => ensemble_object, :old_sigle => "root", :s_annee => "2", :s_obligatoire => "obligatoire"
        assert_response :success

    end

    test "remove" do

        e = default_ensemble("e")
        e.save()

        e = default_ensemble("root")
        e.contenu = "e 1 false"
        e.save()

        # Création de l'arbre

        get :initialize_tree, :base => "root"
        assert_response :success

        # Manque de paramètres

        get :remove
        assert_response :success

        # Paramètres invalides

        get :remove, :parent => "WRONG", :sigle => "WRONG"
        assert_response :success

        # Paramètres valides, suppression du sous arbre

        get :remove, :parent => "root", :sigle => "e"
        assert_response :success

        # Paramètres valides, suppression de la racine

        get :remove, :parent => nil, :sigle => "root"
        assert_response :success

    end

    test "save_all" do

        e = default_ensemble("e")
        e.save()

        e = default_ensemble("root")
        e.contenu = "e 1 false"
        e.save()

        # Sauvegarde alors que rien n'est chargé

        get :save_all
        assert_response :success

        # Création de l'arbre

        get :initialize_tree, :base => "root"
        assert_response :success

        # Sauvegarde sans validité

        get :save_all
        assert_response :success

        # Sauvegarde avec mauvaise validité

        get :save_all, :validite => (Date.today.year - 2).to_s
        assert_response :success

        # Sauvegarde correcte

        get :save_all, :validite => (Date.today.year + 2).to_s
        assert_response :success

    end

    test "update_all" do

        e2 = default_ensemble("e")
        e2.save()

        e = default_ensemble("root")
        e.contenu = "e 1 false"
        e.save()

        # Mise à jour alors que rien n'est chargé

        get :update_all
        assert_response :success

        # Création de l'arbre

        get :initialize_tree, :base => "root"
        assert_response :success

        # Mise à jour

        get :update_all
        assert_response :success

        # Suppression de la racine dans la base de donnée    

        e2.destroy()
        e.destroy()

        # Mise à jour alors que plus aucune correspondance dans la base de donnée n'existe

        get :update_all
        assert_response :success

    end

end
