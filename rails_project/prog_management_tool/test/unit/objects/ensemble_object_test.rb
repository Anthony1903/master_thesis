# encoding: utf-8

require 'test_helper'

class EnsembleObjectTest < ActiveSupport::TestCase
    
    test "create/load ensemble" do

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s1","s2","s3"]
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id = co.save
        assert(c_id>0)

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s4"] 
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id2 = co.save
        assert(c_id2>0)

        contenu =  "s1 1 false, s4 1-2 false"

        param = {}
        param[:creditsMax] = 12
        param[:creditsMin] = 10
        param[:langue] = "fr"
        param[:sigles] = ["s5"] 
        param[:dptCharge] = "INGI"
        param[:intitule] = "intitule"
        param[:contenu] = contenu
        param[:commentaire] = "commentaire"
        param[:validite] = 2012
        param[:import_commentaire] = "import commentaire"
        param[:status] = "actuel"

        eo = EnsembleObject.new(param)
        assert !eo.persisted?
        id = eo.save
        assert (id>=0)
        assert eo.persisted?

        eo2 =  EnsembleObject.new()
        assert !eo2.persisted?
        assert eo2.load(id)
        assert eo2.persisted?

        assert (eo.creditsMax == eo2.creditsMax) 
        assert (eo2.creditsMax == 12)

        assert (eo.creditsMin == eo2.creditsMin) 
        assert (eo2.creditsMin == 10)

        assert (eo.intitule == eo2.intitule) 
        assert (eo2.intitule == "intitule")

        assert (eo.langue == eo2.langue)  
        assert (eo2.langue == "fr")

        assert (eo.sigles == eo2.sigles) 
        assert (eo2.sigles == "s5")

        assert (eo.dptCharge == eo2.dptCharge) 
        assert (eo2.dptCharge == "INGI")

        assert (eo.contenu == eo2.contenu) 
        assert (eo2.contenu == contenu)
       
        assert (eo.commentaire == eo2.commentaire) 
        assert (eo2.commentaire == "commentaire")

        assert (eo.validite == eo2.validite) 
        assert (eo2.validite == 2012)

        assert (eo.import_commentaire == eo2.import_commentaire) 
        assert (eo2.import_commentaire == "import commentaire")

        assert (eo.status == eo2.status) 
        assert (eo2.status == "actuel")

    end

    def compare(e1, e2)

        # Ne compare pas les sigles car ils ne peuvent jamais être les mêmes si il n'y en a qu'un
        assert (e1.creditsMax == e2.creditsMax) 
        assert (e1.creditsMin == e2.creditsMin) 
        assert (e1.intitule == e2.intitule) 
        assert (e1.langue == e2.langue)  
        assert (e1.dptCharge == e2.dptCharge)
        assert (e1.contenu == e2.contenu) 
        assert (e1.commentaire == e2.commentaire) 
        assert (e1.validite == e2.validite) 
        assert (e1.import_commentaire == e2.import_commentaire) 
        assert (e1.status == e2.status) 
        
    end

    test "extract_params" do

        params = {}
        params[:creditsMax] = 6
        params[:creditsMin] = 6
        params[:intitule] = "intitule"
        params[:langue] = "fr"
        params[:sigles] = ["s"]
        params[:dptCharge] = "INGI"
        params[:contenu] = [['s1', 1, true],['s2', 2, false]]
        params[:commentaire] = "commentaire"
        params[:validite] = 2012
        params[:import_commentaire] = "import commentaire"
        params[:status] = "actuel" 

        eo = EnsembleObject.new(params)

        ep = eo.extract_params()

        assert ep[:creditsMax] == params[:creditsMax]
        assert ep[:creditsMin] == params[:creditsMin]
        assert ep[:intitule] == params[:intitule]
        assert ep[:langue] == params[:langue]
        assert ep[:sigles] == params[:sigles]
        assert ep[:mtype] == "ensemble"
        assert ep[:dptCharge] == params[:dptCharge]
        assert ep[:contenu] == params[:contenu]
        assert ep[:commentaire] == params[:commentaire]
        assert ep[:validite] == params[:validite]
        assert ep[:import_commentaire] == params[:import_commentaire]
        assert ep[:status] == params[:status]

    end

    test "get_content_array" do 
        
        eo = default_ensemble("eo")
        eo.contenu = "a 1 true, b 2 false, c 3 true"

        assert eo.get_content_array == [["a", "1", true], ["b", "2", false], ["c", "3", true]]

    end

    test "set_content_array" do 

        eo = default_ensemble("eo")
        eo.set_content_array ([["a", "1", true], ["b", "2", false], ["c", "3", true]])

        assert  eo.contenu == "a 1 true, b 2 false, c 3 true"

    end

    test "update_params" do

        params = {}
        params[:creditsMax] = 0
        params[:creditsMin] = 0
        params[:intitule] = ""
        params[:langue] = ""
        params[:sigles] = ""
        params[:dptCharge] = ""
        params[:contenu] = ""
        params[:commentaire] = ""
        params[:validite] = 0
        params[:import_commentaire] = ""
        params[:status] = "" 

        c = CoursObject.new(params)

        params = {}
        params[:creditsMax] = 6
        params[:creditsMin] = 6
        params[:intitule] = "intitule"
        params[:langue] = "fr"
        params[:sigles] = ["s4"]
        params[:dptCharge] = "INGI"
        params[:contenu] = "s1 1 true"
        params[:commentaire] = "commentaire"
        params[:validite] = 2012
        params[:import_commentaire] = "import commentaire"
        params[:status] = "actuel" 

        c.update_params(params)

        c.extract_params == params

    end

    test "compaire" do 

        params = {}
        params[:creditsMax] = 6
        params[:creditsMin] = 6
        params[:intitule] = "intitule"
        params[:langue] = "fr"
        params[:sigles] = ["s4"]
        params[:dptCharge] = "INGI"
        params[:contenu] = "s1 1 true"
        params[:commentaire] = "commentaire"
        params[:validite] = 2012
        params[:import_commentaire] = "import commentaire"
        params[:status] = "actuel"
        params[:mtype] = "ensemble"

        eo = EnsembleObject.new(params)

        assert eo.compaire(params) == nil

        params[:creditsMax] = 0
        assert eo.compaire(params).size == 1

        params[:creditsMin] = 0
        assert eo.compaire(params).size == 2

        params[:intitule] = ""
        assert eo.compaire(params).size == 3
        
        params[:langue] = ""
        assert eo.compaire(params).size == 4
        
        params[:sigles] = ""
        assert eo.compaire(params).size == 5
        
        params[:dptCharge] = ""
        assert eo.compaire(params).size == 6
        
        params[:contenu] = ""
        assert eo.compaire(params).size == 7
        
        params[:commentaire] = ""
        assert eo.compaire(params).size == 8
        
        params[:validite] = 0
        assert eo.compaire(params).size == 9
        
        params[:import_commentaire] = ""
        assert eo.compaire(params).size == 10
        
        # Le status n'est pas comparé
        params[:status] = ""
        assert eo.compaire(params).size == 10

        params[:mtype] = ""
        assert eo.compaire(params).size == 11

    end

    test "update ensemble" do

        c_params = {}
        c_params[:creditsMax] = 6
        c_params[:sigles] = ["s1","s2","s3"] 
        c_params[:dureeCours] = 27.75
        c_params[:dureeTP] = 30

        co = CoursObject.new(c_params)
        c_id = co.save
        assert(c_id>0)

        params = {}
        params[:creditsMax] = 6
        params[:creditsMin] = 6
        params[:intitule] = "intitule"
        params[:langue] = "fr"
        params[:sigles] = ["s4"]
        params[:dptCharge] = "INGI"
        params[:contenu] = "s1 1 true"
        params[:commentaire] = "commentaire"
        params[:validite] = 2012
        params[:import_commentaire] = "import commentaire"
        params[:status] = "actuel"

        params2 = {}
        params2[:creditsMax] = 6
        params2[:creditsMin] = 0
        params2[:intitule] = "intitule2"
        params2[:langue] = "angl"
        params2[:sigles] = ["s5"] 
        params2[:dptCharge] = "INGI2"
        params2[:contenu] = "s1 2-3 false"
        params2[:commentaire] = "commentaire2"
        params2[:validite] = 2013
        params2[:import_commentaire] = "import commentaire2"
        params2[:status] = "archive"

        eo1 = EnsembleObject.new(params)
        id1 = eo1.save
        assert id1>=0

        eo2 = EnsembleObject.new(params2)
        id2 = eo2.save
        assert id2>=0

        new_oe1 = EnsembleObject.new
        assert new_oe1.load(id1) == true

        params2[:sigles] = ["s14"]       # Autrement, impossible de mettre à jour car s4 et s5 sont déjà utilisés

        assert new_oe1.update(params2)

        new_oe2 = EnsembleObject.new
        assert new_oe2.load(id2) == true

        compare new_oe1,new_oe2
    end

    test "destroy ensemble" do

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s1","s2","s3"] 
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id = co.save
        assert c_id>0

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 0
        param[:sigles] = ["s4"] 
        param[:dptCharge] = "INGI"
        param[:contenu] = "s1 1 false"


        pml = Pmodule.all.length
        ecl = EnsembleContenu.all.length

        eo = EnsembleObject.new(param)

        assert !eo.persisted?
        assert eo.save>=0
        assert eo.persisted?
        assert eo.destroy
        assert !eo.persisted?

        assert Pmodule.all.length == pml
        assert EnsembleContenu.all.length == ecl

    end

    def check_not_persisted(param)

        pml = Pmodule.all.length
        ecl = EnsembleContenu.all.length

        ec = EnsembleObject.new(param)
        id = ec.save()

        assert (id<0)

        assert Pmodule.all.length == pml
        assert EnsembleContenu.all.length == ecl

    end

    test "transactions on save ensemble" do

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 0
        param[:sigles] = ["s1","s2","s3"] 
        param[:dptCharge] = "INGI"
        param[:contenu] = "abc" # <= invalide
        param[:commentaire] = "commentaire"

        check_not_persisted(param)

        param[:contenu] = "42 1" # <= invalide

        check_not_persisted(param)

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s4"] 
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id = co.save

        param[:contenu] = "s4 a false" # <= invalide

        check_not_persisted(param)

        param[:contenu] = "s4 12" # <= invalide

        check_not_persisted(param)

        param[:contenu] = "s4 1-2" # <= invalide

        check_not_persisted(param)

        param[:contenu] = "s4 1-2 false"

        eo1 = EnsembleObject.new(param)
        id1 = eo1.save
        assert (id1>=0)

    end

    def check_not_changed(id, new_param)
        eo = EnsembleObject.new()
        assert eo.load(id)

        eo2 = EnsembleObject.new()
        assert (eo2.load(id))

        r = eo2.update(new_param)

        assert (r==false)

        eo2 = EnsembleObject.new()
        assert (eo2.load(id)) 
        compare(eo,eo2)
    end

    test "transactions on update ensemble" do

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s1","s2","s3"] 
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id = co.save
        assert(c_id>0)

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 6
        param[:sigles] = ["s4"] 
        param[:dptCharge] = "INGI"
        param[:contenu] = "s1 1 true"

        eo = EnsembleObject.new(param)
        id = eo.save
        assert (id>0)

        param2 = {}
        param2[:creditsMax] = 6
        param2[:creditsMin] = 0
        param2[:intitule] = "intitule"
        param2[:langue] = "fr"
        param2[:sigles] = ["s5"] 
        param2[:dptCharge] = "INGI"
        param2[:contenu] = "s1 42 false" # <= invalide

        check_not_changed(id, param2)

        param2[:contenu] = "s1 a false"  # <= invalide

        check_not_changed(id, param2)

        param2[:contenu] = "42 a false"   # <= invalide

        check_not_changed(id, param2)

        param2[:contenu] = "s4 1-2"   # <= invalide

        check_not_changed(id, param2)

    end

    test "credits on ensemble/content" do

        c_param = {}
        c_param[:creditsMax] = 5
        c_param[:sigles] = ["s1","s2","s3"]
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id = co.save
        assert(c_id>0)

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s4"] 
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30

        co = CoursObject.new(c_param)
        c_id2 = co.save
        assert(c_id2>0)

        contenu =  "s1 1 true, s4 1-2 false"

        param = {}
        param[:creditsMax] = -1         # WRONG
        param[:creditsMin] = -1         # WRONG
        param[:sigles] = ["s5"] 
        param[:contenu] = contenu

        # Tests on save

        eo = EnsembleObject.new(param)
        id = eo.save
        assert (id<0)

        param[:creditsMax] = 5        # WRONG
        param[:creditsMin] = 6        # WRONG

        eo = EnsembleObject.new(param)
        id = eo.save
        assert (id<0)

        param[:creditsMax] = 13       # WRONG
        param[:creditsMin] = 13       # WRONG

        eo = EnsembleObject.new(param)
        id = eo.save
        assert (id<0)

        param[:creditsMax] = 11        
        param[:creditsMin] = 5       

        eo = EnsembleObject.new(param)
        id = eo.save
        assert (id>=0)

        # Tests on updates

        param[:creditsMax] = 5        # WRONG
        param[:creditsMin] = 6        # WRONG

        assert(!eo.update(param))

        param[:creditsMax] = 13       # WRONG
        param[:creditsMin] = 13       # WRONG

        assert(!eo.update(param))

        param[:creditsMax] = 5       
        param[:creditsMin] = 5        
        
        assert(eo.update(param))

    end

    test "remove on contained cours" do

        c_param = {}
        c_param[:creditsMax] = 6
        c_param[:sigles] = ["s1","s2","s3"]
        c_param[:dureeCours] = 27.75
        c_param[:dureeTP] = 30
        co = CoursObject.new(c_param)
        c_id = co.save
        assert(c_id>0)

        contenu =  "s1 1 false"

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 0
        param[:sigles] = ["s5"] 
        param[:dptCharge] = "INGI"
        param[:contenu] = contenu

        eo = EnsembleObject.new(param)
        id = eo.save
        assert(id>=0)

        assert(!co.destroy)
        assert(eo.destroy)
        assert(co.destroy)

    end

     test "destroy ensemble but contrainte" do

        param = {}
        param[:creditsMax] = 5
        param[:creditsMin] = 0
        param[:sigles] = ["s1", "s2"] 
        param[:dptCharge] = "INGI"
        param[:contenu] = nil

   
        param2 = {}
        param2[:creditsMax] = 5
        param2[:creditsMin] = 0
        param2[:sigles] = ["s3"] 
        param2[:dptCharge] = "INGI"
        param2[:contenu] = nil

        e = EnsembleObject.new(param)      # sauve e
        assert (e.save>=0)
        e2 = EnsembleObject.new(param2)    # sauve e2
        assert (e2.save>=0)

        assert (e.destroy)
        assert (e.save>=0)

        param = {}
        param[:target] = "*"
        param[:cond] = "s1"
        param[:effet] = "s3"
        id = ContrainteObject.new(param).save # contrainte interdisant la suppression de e et test de suppression de e
        assert (!e.destroy)
        co = ContrainteObject.new()
        co.load(id)
        co.destroy                            # suppression de la contrainte et test de suppression de e
        assert (e.destroy)

        assert (e.save>=0)                    # resauvegarde de e 

        param = {}
        param[:target] = "*"
        param[:cond] = "s3"
        param[:effet] = "s2"
        id = ContrainteObject.new(param).save # contrainte interdisant la suppression de e et test de suppression de e
        assert (!e.destroy)
        co = ContrainteObject.new()
        co.load(id)
        co.destroy                            # suppression de la contrainte et test de suppression de e
        assert (e.destroy)

   end

   test "load_all" do

    eo = default_ensemble("s")
    assert eo.save

    eo2 = default_ensemble("s2")
    assert eo2.save
   
    list = EnsembleObject.load_all()
    assert list.size == 2
    assert list[0].sigles == "s" || list[0].sigles == "s2"
    assert list[1].sigles == "s" || list[1].sigles == "s2"
    assert list[0].sigles != list[1].sigles

   end

end