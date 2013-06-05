
class EnsembleLoaderTest < ActiveSupport::TestCase
  
    def load_cours(extern_id, hashes)

        report = Report.new
        params = {}

        @cours_loader = CoursLoader.new(hashes)
        r = @cours_loader.load_a_cours(params, extern_id, report, false)

        assert r == true
        assert report.empty?

    end

    def load_files()

        @fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")},
               {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")},
               {:name => "EPL_grp", :path => File.expand_path("test/unit/import_manager/files/EPL_grp.test")}]
        h = CsvHasher.new(@fnames)
        b, hashes = h.load

        assert b
        assert hashes!=nil

        return hashes

    end

    def load_and_check_report(hashes, extern_id, cat, number, res)

        report = Report.new
        params = {}

        @ensemble_loader = EnsembleLoader.new(hashes)
        r = @ensemble_loader.load_an_ensemble(params, extern_id, report, false)

        assert r == res
        assert report.categories? == [cat]
        assert report.get_category(cat).size == number

        return params

    end

    test "normal case" do

        hashes = load_files()

        load_cours("1", hashes)
        load_cours("2", hashes)

        report = Report.new()
        params = {}
        extern_id = "3"

        @ensemble_loader = EnsembleLoader.new(hashes)
        r = @ensemble_loader.load_an_ensemble(params, extern_id, report, false)

        assert r == true
        assert report.empty?

        e = EnsembleObject.new()

        id = Sigle.find_by_sigle("LBIR1200I").pmodule_id
        assert(id != nil)

        e.load(id)

        assert e.sigles == "LBIR1200I"
        assert e.creditsMin == 4
        assert e.creditsMax == 10
        assert e.intitule == "intit"
        assert e.langue == "fr"
        assert e.dptCharge == "AGRO"
        assert e.commentaire == "commentaire sur l'option."
        assert e.mtype == "ensemble"
        assert e.validite == 2012
        assert e.import_commentaire == nil
        assert (e.contenu == "LBIR1210 1-2-3 true, LBIR1203 1-2-3 false" || e.contenu == "LBIR1203 1-2-3 false, LBIR1210 1-2-3 true") 

    end

    test "test warnings" do

        hashes = load_files()

        # Aucun cours n'est obligatoire (évite des messages d'erreurs pour les crédits)
        hashes["EPL_grp"]["3"][0]["LIEN_OBLIG"] = "0"
        hashes["EPL_grp"]["3"][1]["LIEN_OBLIG"] = "0"

        load_cours("1", hashes)
        load_cours("2", hashes)

        extern_id = "3"    

        hashes["activites"]["3"][0]["CONTRAINTE2"] = "0"
        hashes["activites"]["3"][0]["CONTRAINTE5"] = "0"

        params = load_and_check_report(hashes, extern_id, "warning", 1, true)

        report = Report.new

        @ensemble_loader = EnsembleLoader.new(hashes)
        r = @ensemble_loader.load_an_ensemble(params, extern_id, report, true) # force == true devrait passer puisqu'on a qu'un warning

        assert r == true

    end

    test "test update" do

        hashes = load_files()

        load_cours("1", hashes)
        load_cours("2", hashes)

        report = Report.new()
        params = {}
        extern_id = "3"

        @ensemble_loader = EnsembleLoader.new(hashes)
        r = @ensemble_loader.load_an_ensemble(params, extern_id, report, false)

        assert r == true
        assert report.empty?

        r = @ensemble_loader.load_an_ensemble(params, extern_id, report, false)
        # Cas de mise à jour où aucun changement n'est proposé 
        assert r == true
        assert report.empty?

        hashes["EPL_grp"]["3"][0]["LIEN_OBLIG"] = "0"
        hashes["EPL_grp"]["3"][1]["LIEN_OBLIG"] = "0"
        # Cas de mise à jour où un changement est proposé 
        load_and_check_report(hashes, extern_id, "update", 1, false)

    end

    test "test (strict) errors" do

        hashes = load_files()

        load_cours("1", hashes)
        load_cours("2", hashes)

        extern_id = "3"

        tmp = hashes["activites"]["3"][0]["CONTRAINTE2"]
        hashes["activites"]["3"][0]["CONTRAINTE2"] = "-1"
        load_and_check_report(hashes, extern_id, "strict error", 1, false)
        hashes["activites"]["3"][0]["CONTRAINTE2"] = tmp

        tmp = hashes["activites"]["3"][0]
        hashes["activites"]["3"][0] = nil
        load_and_check_report(hashes, extern_id, "error", 2, false)
        hashes["activites"]["3"][0] = tmp

        tmp = hashes["activites"]["1"][0]
        hashes["activites"]["1"][0] = nil
        load_and_check_report(hashes, extern_id, "strict error", 1, false)
        hashes["activites"]["1"][0] = tmp

        tmp = hashes["activites"]["2"][0]
        hashes["activites"]["2"][0] = nil
        load_and_check_report(hashes, extern_id, "strict error", 1, false)
        hashes["activites"]["2"][0] = tmp

    end

    test "credits deduction" do

        hashes = load_files()

        load_cours("1", hashes)
        load_cours("2", hashes)

        extern_id = "3"    

        hashes["activites"]["3"][0]["CONTRAINTE2"] = nil
        hashes["activites"]["3"][0]["CONTRAINTE5"] = nil

        params = load_and_check_report(hashes, extern_id, "warning", 3, true)

        assert params[:creditsMin].to_i == 4
        assert params[:creditsMax].to_i == 10

    end

end
