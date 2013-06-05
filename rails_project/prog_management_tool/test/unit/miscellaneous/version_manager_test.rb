# encoding: utf-8

require 'test_helper'

class VersionManagerTest < ActionView::TestCase

	def partial_compaire(eo, params)

        assert eo.creditsMin == params[:creditsMin]
        assert eo.creditsMax == params[:creditsMax]
        assert eo.langue == params[:langue]
        assert eo.dptCharge == params[:dptCharge]
        assert eo.intitule == params[:intitule]
        assert eo.commentaire == params[:commentaire]
        assert eo.validite == params[:validite]
        assert eo.import_commentaire == params[:import_commentaire]
        assert eo.creditsMax == params[:creditsMax]

	end

    def actuel_and_archive?(s1, act_params, s2, arch_params)

        # Verifie que la nouvelle version est correcte

        id = PmoduleObject.id?(s1)
        assert id != nil
        eo = EnsembleObject.new()
        eo.load(id)
        assert eo.compaire(act_params) == nil
        assert eo.status == "actuel"

        # Verifie que l'archive est correcte

        id = PmoduleObject.id?(s2)
        archive_eo = EnsembleObject.new()
        archive_eo.load(id)
        diff = archive_eo.compaire(arch_params)

        # 1 différence : le sigle

        assert diff.length == 1 
        assert diff[:sigles] != nil 
        assert archive_eo.status == "archive"

    end
    
    def future_to_actuel?(fut_s, fut_params, act_s, arch_s = nil, arch_params = nil)
   
        id = PmoduleObject.id?(fut_s)
        assert id == nil

        id = PmoduleObject.id?(act_s)
        assert id != nil
        eo = EnsembleObject.new()
        eo.load(id)
        diff = eo.compaire(fut_params)
        # 1 différence : le sigle
        assert diff.length == 1 
        assert diff[:sigles] != nil 
        assert eo.status == "actuel"

        if(arch_s != nil)
            archive_eo = EnsembleObject.new()  # Verification de l'archive
            id = PmoduleObject.id?(arch_s)
            archive_eo.load(id)
            diff = archive_eo.compaire(arch_params)
            # 1 différence : le sigle
            assert diff.length == 1 
            assert diff[:sigles] != nil 
            assert archive_eo.status == "archive"
        end

    end

    def ensemble_saved?(sigle, params)

        id = PmoduleObject.id?(sigle)
        assert id != nil

        eo = EnsembleObject.new()
        eo.load(id)
        assert eo.compaire(params) == nil

    end

    test "is_main_version?" do
    
        assert VersionManager.is_main_version?("abc")

        assert !VersionManager.is_main_version?("")
        assert !VersionManager.is_main_version?(nil)

        assert !VersionManager.is_main_version?("abc_(2013)")
        assert !VersionManager.is_main_version?("abc_(2013-04-05 15:22:20 +0200)")
    
    end

    test "is_archive?" do
    
        assert !VersionManager.is_archive_version?("abc")
        assert !VersionManager.is_archive_version?("")
        assert !VersionManager.is_archive_version?(nil)

        assert !VersionManager.is_archive_version?("abc_(2013)")
        assert VersionManager.is_archive_version?("abc_(2013-04-05 15:22:20 +0200)")
    
    end

    test "archive" do

        assert !VersionManager.archive(nil)
        assert !VersionManager.archive("")
        assert !VersionManager.archive("c")
        assert !VersionManager.archive("e")

        c = default_cours("c")
        c.save

        assert VersionManager.archive("c")

        e = default_ensemble("e")
        e.save

        assert VersionManager.archive("e")

        # Suite dans le test de "recursive_archive"
    
    end

    # Cas : e (ensemble) contient e2 (ensemble) qui contient c (ensemble)
    #       e est archivé et remplacé
    test "recursive archive" do

        eo1 = default_ensemble("e")
        eo2 = default_ensemble("e2")
        co1 = default_cours("c")

        eo1.contenu = "e2 1 false"
        eo2.contenu = "c 1 false"

        id1 = co1.save
        id2 = eo2.save
        id3 = eo1.save

        assert id1 > 0
        assert id2 > 0
        assert id3 > 0

        r = VersionManager.recursive_archive(eo1)

        assert r == true
        assert Pmodule.all.length == 6

        assert PmoduleObject.id?("c") != nil 
        assert PmoduleObject.id?("e2") != nil 
        assert PmoduleObject.id?("e") != nil

        tmp = CoursObject.new()
        tmp.load(id1) 
        assert tmp.compaire(co1.extract_params) == nil

        tmp = EnsembleObject.new()
        tmp.load(id2) 
        assert tmp.compaire(eo2.extract_params) == nil

        tmp = EnsembleObject.new()
        tmp.load(id3) 
        assert tmp.compaire(eo1.extract_params) == nil

        c_arch = false
        e2_arch = false
        e_arch = false

        Sigle.all.each do |s|
            if(s.sigle.index("c_(")!=nil)
                c_arch = true
                assert Pmodule.find(s.pmodule_id).status == "archive"
            elsif(s.sigle.index("e2_(")!=nil)
                e2_arch = true
                assert Pmodule.find(s.pmodule_id).status == "archive"
            elsif(s.sigle.index("e_(")!=nil)
                e_arch = true
                assert Pmodule.find(s.pmodule_id).status == "archive"
            end           
        end

        assert c_arch
        assert e2_arch
        assert e_arch

    end

    test "try_saving_module" do
        
        e = default_ensemble("e") 
        r = Report.new()
        n = Pmodule.all.size

        # introduction d'une erreur
        e.creditsMax = "-1"


        # Tentative de sauvegarde du module

        assert !VersionManager.try_saving_module(r, e)
        assert !r.empty?
        assert Pmodule.all.size == n

        # correction de l'erreur
        e.creditsMax = e.creditsMin
        r.erase()

        # Tentative de sauvegarde du module
        
        assert VersionManager.try_saving_module(r, e)
        assert r.empty?
        assert Pmodule.all.size == n + 1

    end

    test "try_updating_module" do
            
        e = default_ensemble("e")
        id = e.save()

        r = Report.new()
        n = Pmodule.all.size

        # Premier cas, sans création d'archive
        ######################################

        # introduction d'une erreur

        params = e.extract_params()
        params[:creditsMax] = "-1"

        # Tentative de mise à jour du module

        assert !VersionManager.try_updating_module(r, e, params, false)
        assert !r.empty?
        assert Pmodule.all.size == n

        # correction de l'erreur

        params[:creditsMax] = params[:creditsMin]
        r.erase()

        # Tentative de mise à jour du module

        assert VersionManager.try_updating_module(r, e, params, false)
        assert r.empty?
        assert Pmodule.all.size == n


        # Même schéma mais avec la demande d'archive (dernier paramètre à true)
        #######################################################################

        # réintroduction de l'erreur

        params = e.extract_params()
        params[:creditsMax] = "-1"

        # Tentative de mise à jour du module

        assert !VersionManager.try_updating_module(r, e, params, true)
        assert !r.empty?
        assert Pmodule.all.size == n

        # correction de l'erreur

        params[:creditsMax] = params[:creditsMin]
        r.erase()

        # Tentative de mise à jour du module

        assert VersionManager.try_updating_module(r, e, params, true)
        assert r.empty?
        assert Pmodule.all.size == n + 1 # +1 car archive créée

    end

    test "in_future?" do
        
        assert !VersionManager.in_future?(Date.today.year - 1)
        assert VersionManager.in_future?(Date.today.year + 1)

    end 

    test "adapt_content" do 

        t = Time.now.to_s
        
        assert VersionManager.adapt_content(nil, t) == ""
        assert VersionManager.adapt_content([], t) == ""
       
        ca = [["a", "1", true], ["b", "2", false], ["c", "1-2", true]]
        new_c = VersionManager.adapt_content(ca, t)

        a = VersionManager.concat_time("a", t)
        b = VersionManager.concat_time("b", t)
        c = VersionManager.concat_time("c", t)
        
        assert new_c == "#{a} 1 true, #{b} 2 false, #{c} 1-2 true"

    end

    test "remove_suffix_from_content" do 

        t = Time.now.to_s
        a = VersionManager.concat_time("a", t)
        b = VersionManager.concat_time("b", t)
        c = VersionManager.concat_time("c", t)

        assert = VersionManager.remove_suffix_from_content(nil) == ""
        assert VersionManager.remove_suffix_from_content([]) == ""

        ca = [["#{a}", "1", true], ["#{b}", "2", false], ["#{c}", "1-2", true]]

        new_c = VersionManager.remove_suffix_from_content(ca)

        assert new_c == "a 1 true, b 2 false, c 1-2 true"

    end

	test "archive_version_params" do

		eo = default_ensemble("s")
        archive_params = VersionManager.archive_version_params(eo)

		partial_compaire(eo, archive_params)

        s = archive_params[:sigles][0]
        assert s.index("_(")!=nil
        assert s.index(")")!=nil
        assert s.index(Date.today.year.to_s)!=nil
        assert s.index(Date.today.month.to_s)!=nil
        assert s.index(Date.today.day.to_s)!=nil
        assert archive_params[:status] == "archive"

        eo.sigles = "ABC_(Sat Jan 26 11:14:02 +0100 2013)"
        archive_params = VersionManager.archive_version_params(eo)

        s = archive_params[:sigles][0]
        assert s.index("_(")!=nil
        assert s.index(")")!=nil
        assert s.index(Date.today.year.to_s)!=nil
        assert s.index(Date.today.month.to_s)!=nil
        assert s.index(Date.today.day.to_s)!=nil

	end

	test "future_version_params" do

		eo = default_ensemble("s")
        future_params = VersionManager.future_version_params(eo)

		partial_compaire(eo, future_params)

        assert future_params[:sigles][0] == VersionManager.concat_validite(eo.sigles_array()[0], eo.validite)
        assert future_params[:status] == "future"

        eo.sigles = "ABC_(Sat Jan 26 11:14:02 +0100 2013)"
        future_params = VersionManager.future_version_params(eo)
        assert future_params[:sigles][0] == VersionManager.concat_validite("ABC", eo.validite)

	end

	test "actuel_version_params" do

		eo = default_ensemble("s")
        eo.contenu = "a_(3000) 1 false, b 1 false"
        actuel_params = VersionManager.actuel_version_params(eo)

		partial_compaire(eo, actuel_params)

        assert eo.sigles_array == actuel_params[:sigles]
        assert actuel_params[:status] == "actuel"
        assert actuel_params[:contenu] == "a 1 false, b 1 false"

        eo.sigles = "ABC_(Sat Jan 26 11:14:02 +0100 2013)"
        actuel_params = VersionManager.actuel_version_params(eo)
        assert actuel_params[:sigles] == ["ABC"]

	end

	test "has_suffix" do

		assert VersionManager.has_suffix?("abcd_(abc)")
		assert VersionManager.has_suffix?("abcd_()")
		assert !VersionManager.has_suffix?(nil)
		assert !VersionManager.has_suffix?("abcd")
		assert !VersionManager.has_suffix?("abcd_")
		assert !VersionManager.has_suffix?("abcd_(")
		assert !VersionManager.has_suffix?("abcd_)")
		assert !VersionManager.has_suffix?("abcd_abc)")
		assert !VersionManager.has_suffix?("abcd_(abc")
		assert !VersionManager.has_suffix?("abcd(abc)")
		assert !VersionManager.has_suffix?("abcd_)abc(")

	end	

	test "remove_suffix" do

		assert VersionManager.remove_suffix("abcd_(abc)") == "abcd"
		assert VersionManager.remove_suffix("abcd_()") == "abcd"
		assert VersionManager.remove_suffix("abcd_(abc))") == "abcd"
		assert VersionManager.remove_suffix("abcd_((abc)") == "abcd"
		assert VersionManager.remove_suffix("abcd_(_(abc)") == "abcd"
		assert VersionManager.remove_suffix("abcd_(_(abc))") == "abcd"
		assert VersionManager.remove_suffix("abcd") == "abcd"
		assert VersionManager.remove_suffix("abcd_") == "abcd_"
		assert VersionManager.remove_suffix("abcd(") == "abcd("
		assert VersionManager.remove_suffix("abcd)") == "abcd)"
		assert VersionManager.remove_suffix("abcd_(") == "abcd_("
		assert VersionManager.remove_suffix("abcd_)") == "abcd_)"
		assert VersionManager.remove_suffix("abcd_)(") == "abcd_)("
		assert VersionManager.remove_suffix(nil) == nil

	end	

	test "concat_time" do

    	s = VersionManager.concat_time("abcd")
        assert s.index("_(")!=nil
        assert s.index(")")!=nil
        assert s.index(Date.today.year.to_s)!=nil
        assert s.index(Date.today.month.to_s)!=nil
        assert s.index(Date.today.day.to_s)!=nil

    	s = VersionManager.concat_time(nil)
        assert s.index("_(")!=nil
        assert s.index(")")!=nil
        assert s.index(Date.today.year.to_s)!=nil
        assert s.index(Date.today.month.to_s)!=nil
        assert s.index(Date.today.day.to_s)!=nil

    end

	test "concat_validite " do

        assert VersionManager.concat_validite("abcd",2011) == "abcd_(2011)"
        assert VersionManager.concat_validite("",2012) == "_(2012)"
        assert VersionManager.concat_validite(nil,2013) == "_(2013)"
	
    end

    test "params_according_to_validity" do

        e = default_ensemble("e")

        e.validite = Time.now.year - 2
        params = VersionManager.params_according_to_validity(e.extract_params)
        assert params[:status] == "actuel"
        
        e.validite = Time.now.year + 2
        params = VersionManager.params_according_to_validity(e.extract_params)
        assert params[:status] == "future"

    end

    test "create_module" do

        c = default_cours("c")
        e = default_ensemble("e")

        assert VersionManager.create_module(c.extract_params).kind_of?(CoursObject)
        assert VersionManager.create_module(e.extract_params).kind_of?(EnsembleObject)
        assert VersionManager.create_module(nil) == nil

    end

end