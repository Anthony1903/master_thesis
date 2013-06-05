# encoding: utf-8


class CsvLoaderTest < ActiveSupport::TestCase

    def build_loader()

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")}, 
                  {:name => "activites_root", :path => File.expand_path("test/unit/import_manager/files/activites_root.test")}, 
                  {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}, 
                  {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]
        loader = CSVLoader.new(fnames)

        return loader

    end
 
    test "load_files" do 
        
        # Le fichier n'existe pas

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/WRONG.test")}]
        loader = CSVLoader.new(fnames)

        r, data, fname = loader.load_files
        assert !r
        assert fname.include?("test/unit/import_manager/files/WRONG.test")  # fname contient chemin complet, vérifie que la fin correspond
        assert data == :read_error

        # Le fichier est mal formé

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/hash2.test")}]
        loader = CSVLoader.new(fnames)

        r, data, fname = loader.load_files
        assert !r
        assert fname.include?("test/unit/import_manager/files/hash2.test")  # fname contient chemin complet, vérifie que la fin correspond
        assert data == :format_error

        # Tous les fichiers sont corrects 

        fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")}, 
                  {:name => "activites_root", :path => File.expand_path("test/unit/import_manager/files/activites_root.test")}, 
                  {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}, 
                  {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]
        loader = CSVLoader.new(fnames)

        loader = build_loader()
        r, data, fname = loader.load_files()

        assert r
        assert fname == nil
        assert data == nil

    end 


    test "roots_info" do 

        loader = build_loader()
        loader.load_files()
        roots = loader.roots_info()
        
        assert roots.sort == ["racine","racine2","racine3"].sort

    end 

    test "files_loaded?" do

        loader = build_loader()

        assert !loader.files_loaded?
        
        loader.load_files
        assert loader.files_loaded?

    end

    # Test stack_initial_size, stack_current_size, init_stack et reinit_stack
    test "stack size during proccess" do 

        loader = build_loader()
        loader.load_files

        assert loader.stack_initial_size() == 0
        assert loader.stack_current_size() == 0

        assert !loader.init_stack("wrong")
        assert loader.stack_initial_size() == 0
        assert loader.stack_current_size() == 0

        assert !loader.init_stack(nil)
        assert loader.stack_initial_size() == 0
        assert loader.stack_current_size() == 0

        assert loader.init_stack("racine")
        assert loader.stack_initial_size() == 3
        assert loader.stack_current_size() == 3

        assert loader.load_next() # Le contenu est correcte, possible de tout charger sans erreurs
        assert loader.stack_initial_size() == 3
        assert loader.stack_current_size() == 2

        assert loader.load_next() 
        assert loader.stack_initial_size() == 3
        assert loader.stack_current_size() == 1

        assert loader.load_next() 
        assert loader.stack_initial_size() == 3
        assert loader.stack_current_size() == 0

        assert loader.reinit_stack()
        assert loader.stack_initial_size() == 3
        assert loader.stack_current_size() == 3

        assert loader.init_stack("racine2")
        assert loader.stack_initial_size() == 2
        assert loader.stack_current_size() == 2

    end

    test "load_module" do

        loader = build_loader()
        loader.load_files
        loader.init_stack("racine")
        report = Report.new()

        params1 = {}
        assert loader.load_module(params1, "1", report)
        assert report.empty?
        assert params1[:mtype] == "cours"
        assert params1[:sigles] == "LBIR1210"
        assert loader.reports.empty?

        params2 = {}
        assert loader.load_module(params2, "2", report)
        assert report.empty?
        assert params2[:mtype] == "cours"
        assert params2[:sigles] == "LBIR1203"
        assert loader.reports.empty?
        
        params3 = {}
        assert loader.load_module(params3, "3", report)
        assert report.empty?
        assert params3[:mtype] == "ensemble"
        assert params3[:sigles] == "LBIR1200I"
        assert loader.reports.empty?
        
        params4 = {}
        assert !loader.load_module(params4, "-1", report)
        assert !report.empty?
        assert loader.reports.size == 1
        report.erase

        assert !loader.load_module(params4, "1000", report)
        assert !report.empty?
        assert loader.reports.size == 2

    end

    # Processus complet, ce test joue le rôle du contrôleur lors d'un cas complet
    test "load_next" do 

        loader = build_loader()
        loader.load_files

        # Ajout d'une erreur 
        loader.hashes["activites"]["1"][0]["POIDS"] = "-1"

        loader.init_stack("racine")

        # Chargement du module "2", pas de probleme

        assert loader.state == :waiting
        r = loader.load_next()
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 2
        assert r[:current] == nil 

        # Chargement du module "1", l'erreur survient

        assert loader.state == :waiting
        r = loader.load_next()
        assert loader.state == :wait_feedback
        assert r[:flag] == "error"
        assert !r[:report].empty?
        assert r[:mod].is_a?(CoursObject)
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 1   
        assert r[:current] == nil

        params = r[:mod].extract_params

        assert params[:creditsMin] == -1
        assert params[:creditsMax] == -1

        # Correction de l'erreur

        params[:creditsMax] = 4
        params[:creditsMin] = 4

        loader.set_feedback(params ,nil)
        assert loader.state == :feedback_received

        # Prise en compte de la correction

        r = loader.load_next()
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 1
        assert r[:current] == nil 

        # Chargement du dernier module

        assert loader.state == :waiting
        r = loader.load_next()
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 0
        assert r[:current] == nil 

        # Mise à jour du module "2"

        loader.hashes["activites"]["2"][0]["INTIT_COMPLET"] = "Nouvel intitulé"

        loader.reinit_stack()
        assert loader.state == :waiting
        r = loader.load_next()
        assert loader.state == :wait_feedback
        assert r[:flag] == "update"
        assert !r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 2

        assert r[:mod].is_a?(CoursObject)        # Nouvelle proposition
        assert r[:mod].intitule == "Nouvel intitulé"

        assert r[:current].is_a?(CoursObject)    # Valeur actuelle
        assert r[:current].intitule == "Probabilités et statistiques (I)"

        # Traitement de la demande de mise à jour par la conservation de la version actuelle

        assert loader.state == :wait_feedback
        loader.set_feedback(:keep, nil)
        assert loader.state == :feedback_received
        r = loader.load_next()
        assert loader.state == :waiting
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 2
        assert r[:current] == nil 

        # Réessai de la mise à jour

        loader.reinit_stack()
        assert loader.state == :waiting
        r = loader.load_next()
        assert loader.state == :wait_feedback
        assert r[:flag] == "update"
        assert !r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 2

        assert r[:mod].is_a?(CoursObject)        # Nouvelle proposition
        assert r[:mod].intitule == "Nouvel intitulé"

        assert r[:current].is_a?(CoursObject)    # Valeur actuelle
        assert r[:current].intitule == "Probabilités et statistiques (I)"

        # Traitement de la demande de mise à jour par la conservation de la nouvelle version

        loader.set_feedback(r[:mod].extract_params, nil)
        assert loader.state == :feedback_received
        r = loader.load_next()
        assert loader.state == :waiting
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 2
        assert r[:current] == nil 

        # Réessai de la mise à jour, plus rien ne devrait se passer puisque la version est déjà à jour

        loader.reinit_stack()
        assert loader.state == :waiting
        r = loader.load_next()
        assert loader.state == :waiting
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 3
        assert r[:stack_current_size] == 2      
        assert r[:current] == nil

        # Import d'un ensemble dont le contenu ne figure pas dans la table activité (module unknown)

        loader.init_stack("racine3")
        r = loader.load_next()
        assert loader.state == :wait_feedback
        assert r[:flag] == "error"
        assert !r[:report].empty?
        assert r[:stack_initial_size] == 2
        assert r[:stack_current_size] == 1
        assert r[:current] == nil 

        assert r[:mod].is_a?(EnsembleObject)         
        assert r[:mod].intitule == "Module inconnu"
        assert r[:mod].sigles.include?("UNKNOWN")
        assert r[:mod].sigles.include?("7")
        assert r[:mod].creditsMin == 28
        assert r[:mod].creditsMax == 28

        # Force la sauvegarde de ce module inconnu en tant que tel

        params = r[:mod].extract_params
        params[:contenu] = r[:mod].contenu # Feedback nécessite un string et non un tableau

        loader.set_feedback(params, nil)
        assert loader.state == :feedback_received
        r = loader.load_next()
        assert loader.state == :waiting
        assert r[:flag] == "valid"
        assert !r[:report].empty?       # Existe un warning car ensemble sauvé avec un contenu vide
        assert r[:stack_initial_size] == 2
        assert r[:stack_current_size] == 1
        assert r[:current] == nil 

        # Charge l'ensemble contenant le module inconnu (pas de problème)

        r = loader.load_next()
        assert loader.state == :waiting
        assert r[:flag] == "valid"
        assert r[:report].empty?
        assert r[:stack_initial_size] == 2
        assert r[:stack_current_size] == 0
        assert r[:current] == nil 

    end

end

