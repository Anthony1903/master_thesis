# encoding: utf-8


class CoursLoaderTest < ActiveSupport::TestCase

    def load_files()

        @fnames = [{:name => "activites", :path => File.expand_path("test/unit/import_manager/files/activites.test")},
                   {:name => "prof", :path => File.expand_path("test/unit/import_manager/files/prof.test")}]
        h = CsvHasher.new(@fnames)
        b, hashes = h.load

        assert b
        assert hashes!=nil

        return hashes

    end

    def load_and_check_report(hashes, extern_id, cat, number, res)

        report = Report.new
        params = {}

        @cours_loader = CoursLoader.new(hashes)
        r = @cours_loader.load_a_cours(params, extern_id, report, false)

        assert r == res
        assert report.categories? == [cat]
        assert report.get_category(cat).size == number

    return params

    end

    test "normal case" do

        hashes = load_files()

        report = Report.new
        params = {}
        extern_id = "1"

        @cours_loader = CoursLoader.new(hashes)
        r = @cours_loader.load_a_cours(params, extern_id, report, false)

        assert r == true
        assert report.empty?

        c = CoursObject.new()

        id = Sigle.find_by_sigle("LBIR1210").pmodule_id

        assert(id != nil)

        assert c.load(id)

        assert c.sigles == "LBIR1210"
        assert c.dureeCours == 60
        assert c.dureeTP == 60
        assert c.quadri == 2
        assert c.professeur == "Bieliavsky Pierre"
        assert c.creditsMin == 4
        assert c.creditsMax == 4
        assert c.intitule == "Physique générale (II)"
        assert c.langue == "fr"
        assert c.dptCharge == "AGRO"
        assert c.commentaire == nil
        assert c.mtype == "cours"
        assert c.validite == 2012
        assert c.import_commentaire == nil

    end

    test "warnings" do

        hashes = load_files()

        extern_id = "1"

        hashes["activites"]["1"][0]["POIDS"] = "0"

        params = load_and_check_report(hashes, extern_id, "warning", 1, true)

        report = Report.new

        @cours_loader = CoursLoader.new(hashes)
        
        # force == true devrait passer puisqu'on a qu'un warning
        r = @cours_loader.load_a_cours(params, extern_id, report, true) 
        assert r == true

    end

    test "update" do

        hashes = load_files()

        report = Report.new
        params = {}
        extern_id = "1"

        @cours_loader = CoursLoader.new(hashes)
        r = @cours_loader.load_a_cours(params, extern_id, report, false)

        assert r == true
        assert report.empty?

        r = @cours_loader.load_a_cours(params, extern_id, report, false)
        # Cas de mise à jour où aucun changement n'est proposé 
        assert r == true
        assert report.empty?

        hashes["activites"]["1"][0]["POIDS"] = "10"
        # Cas de mise à jour où un changement est proposé 
        load_and_check_report(hashes, extern_id, "update", 1, false)

    end

    test "strict errors" do

        hashes = load_files()

        extern_id = "1"

        tmp = hashes["activites"]["1"][0]["POIDS"]
        hashes["activites"]["1"][0]["POIDS"] = "-1"
        load_and_check_report(hashes, extern_id, "strict error", 2, false)
        hashes["activites"]["1"][0]["POIDS"] = tmp

        tmp = hashes["activites"]["1"][0]["VOL_TOT1"]
        hashes["activites"]["1"][0]["VOL_TOT1"] = "-1"
        load_and_check_report(hashes, extern_id, "strict error", 1, false)

        # Inutile de tester d'autres erreurs car les erreurs causées lors d'un chargement de cours sont celles 
        # causée à la création du cours uniquement (d'autres tests sont prévu pour cette situation).
        # Le fait de charger un cours n'induit pas d'erreur supplémentaire.

    end

end
