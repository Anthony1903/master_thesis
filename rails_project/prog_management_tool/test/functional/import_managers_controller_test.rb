require 'test_helper'

class ImportManagersControllerTest < ActionController::TestCase

    test "index" do

        get :index
        assert_response :success

    end

    test "load_files" do

        # Erreur fichier

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/WRONG.test")}]

        get :load_files, :file_names => fnames
        assert_response :success

        # Erreur format

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/hash2.test")}]

        get :load_files, :file_names => fnames
        assert_response :success

        # Cas normal 

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")}, 
            {:name => "activites_root", :path => File.expand_path("test/unit/import_manager/files/activites_root.test")}, 
            {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}, 
            {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]

        get :load_files, :file_names => fnames

        assert_response :success

    end

    test "load_next" do

        # Cas ou il est impossible de faire l'action car aucun fichier n'a été chargé

        get :load_next
        assert_response :success

        # Cas ou aucune racine n'a été sélectionnée

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")}, 
            {:name => "activites_root", :path => File.expand_path("test/unit/import_manager/files/activites_root.test")}, 
            {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}, 
            {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]

        get :load_files, :file_names => fnames

        get :load_next
        assert_response :success

        # Cas normal

        get :load_next, :root_selected => "racine"
        assert_response :success

    end

    test "feedback" do

        # Cas ou load_next ne sera pas rendu car aucun fichier chargé

        get :feedback, :keep => "true"
        assert_response :success

        # Cas ou load_next sera effectivement rendu

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")}, 
            {:name => "activites_root", :path => File.expand_path("test/unit/import_manager/files/activites_root.test")}, 
            {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}, 
            {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]

        get :load_files, :file_names => fnames

        get :feedback
        assert_response :success

        get :feedback, :keep => "true"
        assert_response :success

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

        get :feedback, :mtype => "ensemble", :ensemble_object => ensemble_object
        assert_response :success

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
        get :feedback, :mtype => "cours", :cours_object => cours_object
        assert_response :success

    end

    test "init_stack" do

        # Cas où les fichiers n'ont pas encore été chargés

        get :init_stack
        assert_response :success

        # Cas normal

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")}, 
            {:name => "activites_root", :path => File.expand_path("test/unit/import_manager/files/activites_root.test")}, 
            {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}, 
            {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]

        get :load_files, :file_names => fnames

        get :init_stack
        assert_response :success

    end
  
end
