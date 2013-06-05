# encoding: utf-8

require 'test_helper'

class CoursObjectTest < ActiveSupport::TestCase

    test "create/load cours" do

        param = {}
        param[:creditsMax] = 5
        param[:intitule] = "intitule"
        param[:langue] = "fr"
        param[:sigles] = ["s1","s2","s3"]
        param[:dureeCours] = 27.75
        param[:dureeTP] = 30
        param[:quadri] = 1
        param[:dptCharge] = "INGI"
        param[:professeur] = "professeur"
        param[:commentaire] = "commentaire"
        param[:validite] = 2012
        param[:import_commentaire] = "import commentaire"
        param[:status] = "actuel"

        co = CoursObject.new(param)
        assert !co.persisted?
        id = co.save
        assert (id>=0)
        assert co.persisted?

        co2 =  CoursObject.new()
        assert !co2.persisted?
        assert co2.load(id)
        assert co2.persisted?

        assert (co.creditsMax == co2.creditsMax) 
        assert (co2.creditsMax == 5)

        assert (co.creditsMin == co2.creditsMin) 
        assert (co2.creditsMin == 5)

        assert (co.intitule == co2.intitule) 
        assert (co2.intitule == "intitule")

        assert (co.langue == co2.langue)  
        assert (co2.langue == "fr")

        assert (co.sigles == co2.sigles) 
        assert (co2.sigles_array == ["s1","s2","s3"])

        assert (co.dureeCours == co2.dureeCours) 
        assert (co2.dureeCours == 27.75)

        assert (co.dureeTP == co2.dureeTP) 
        assert (co2.dureeTP == 30)

        assert (co.quadri == co2.quadri) 
        assert (co2.quadri == 1)

        assert (co.dptCharge == co2.dptCharge) 
        assert (co2.dptCharge == "INGI")

        assert (co.professeur == co2.professeur) 
        assert (co2.professeur == "professeur")

        assert (co.commentaire == co2.commentaire) 
        assert (co2.commentaire == "commentaire")

        assert (co.validite == co2.validite) 
        assert (co2.validite == 2012)

        assert (co.import_commentaire == co2.import_commentaire) 
        assert (co2.import_commentaire == "import commentaire")

        assert (co.status == co2.status) 
        assert (co2.status == "actuel")

    end

    def compare(c1, c2)

        # Ne compare pas les sigles car ils ne peuvent jamais être les mêmes
        assert (c1.creditsMax == c2.creditsMax) 
        assert (c1.creditsMin == c2.creditsMin) 
        assert (c1.intitule == c2.intitule) 
        assert (c1.langue == c2.langue)  
        assert (c1.dureeCours == c2.dureeCours) 
        assert (c1.dureeTP == c2.dureeTP) 
        assert (c1.quadri == c2.quadri) 
        assert (c1.dptCharge == c2.dptCharge) 
        assert (c1.professeur == c2.professeur) 
        assert (c1.commentaire == c2.commentaire) 
        assert (c1.validite == c2.validite) 
        assert (c1.import_commentaire == c2.import_commentaire) 
        assert (c1.status == c2.status) 

    end

    test "create/load cours with defaults values" do

        param = {}
        param[:creditsMax] = 5
        param[:creditsMin] = 5
        param[:intitule] = nil
        param[:langue] = "fr-angl"
        param[:sigles] = ["s1","s2","s3"]
        param[:dureeCours] = 27.75
        param[:dureeTP] = 30
        param[:quadri] = 1
        param[:dptCharge] = nil
        param[:professeur] = nil
        param[:commentaire] = nil
        param[:validite] = nil
        param[:import_commentaire] = nil
        param[:status] = "actuel"

        c1 = CoursObject.new(param)

        param2 = {}
        param2[:creditsMax] = 5
        param2[:creditsMin] = 5
        param2[:sigles] = ["s4","s5","s6"]
        param2[:dureeCours] = 27.75
        param2[:dureeTP] = 30
        param2[:quadri] = 1

        c2 = CoursObject.new(param2)

        compare(c1,c2)

        id1 = c1.save
        assert (id1>=0)

        id2 = c2.save
        assert (id2>=0)

        new_c1 = CoursObject.new
        assert (new_c1.load(id1) == true)

        new_c2 = CoursObject.new
        assert (new_c2.load(id2) == true)

        compare(c1,new_c1)
        compare(c2,new_c2)
        compare(new_c1,new_c2)

    end

    test "extract_params" do

        params = {}
        params[:creditsMax] = 6
        params[:creditsMin] = 5
        params[:intitule] = "intitule"
        params[:langue] = "fr"
        params[:sigles] = ["s1","s2","s3"]
        params[:dureeCours] = 27.75
        params[:dureeTP] = 30
        params[:quadri] = 1
        params[:dptCharge] = "INGI"
        params[:professeur] = "professeur"
        params[:commentaire] = "commentaire"
        params[:validite] = 2012
        params[:import_commentaire] = "import commentaire"
        params[:status] = "actuel"

        c = CoursObject.new(params)

        ep = c.extract_params()

        assert ep[:creditsMax] == params[:creditsMax]
        assert ep[:creditsMin] == params[:creditsMin]
        assert ep[:intitule] == params[:intitule]
        assert ep[:langue] == params[:langue]
        assert ep[:sigles] == params[:sigles]
        assert ep[:dureeCours] == params[:dureeCours]
        assert ep[:dureeTP] == params[:dureeTP]
        assert ep[:quadri] == params[:quadri]
        assert ep[:mtype] == "cours"
        assert ep[:dptCharge] == params[:dptCharge]
        assert ep[:professeur] == params[:professeur]
        assert ep[:commentaire] == params[:commentaire]
        assert ep[:validite] == params[:validite]
        assert ep[:import_commentaire] == params[:import_commentaire]
        assert ep[:status] == params[:status]

    end

    test "update_params" do

        params = {}
        params[:creditsMax] = 0
        params[:creditsMin] = 0
        params[:intitule] = ""
        params[:langue] = ""
        params[:sigles] = ""
        params[:dureeCours] = 0
        params[:dureeTP] = 0
        params[:quadri] = 0
        params[:dptCharge] = ""
        params[:professeur] = ""
        params[:commentaire] = ""
        params[:validite] = 0
        params[:import_commentaire] = ""
        params[:status] = ""

        c = CoursObject.new(params)

        params = {}
        params[:creditsMax] = 6
        params[:creditsMin] = 5
        params[:intitule] = "intitule"
        params[:langue] = "fr"
        params[:sigles] = ["s1","s2","s3"]
        params[:dureeCours] = 27.75
        params[:dureeTP] = 30
        params[:quadri] = 1
        params[:dptCharge] = "INGI"
        params[:professeur] = "professeur"
        params[:commentaire] = "commentaire"
        params[:validite] = 2012
        params[:import_commentaire] = "import commentaire"
        params[:status] = "actuel"

        c.update_params(params)

        c.extract_params == params

    end

    test "update cours" do

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 5
        param[:intitule] = "intitule"
        param[:langue] = "fr"
        param[:sigles] = ["s1","s2","s3"]
        param[:dureeCours] = 27.75
        param[:dureeTP] = 30
        param[:quadri] = 1
        param[:dptCharge] = "INGI"
        param[:professeur] = "professeur"
        param[:commentaire] = "commentaire"
        param[:validite] = 2012
        param[:import_commentaire] = "import commentaire"
        param[:status] = "actuel"

        param2 = {}   
        param2[:creditsMax] = 4
        param2[:creditsMin] = 4
        param2[:intitule] = "intitule2"
        param2[:langue] = "angl"
        param2[:sigles] = ["s4"]
        param2[:dureeCours] = 15
        param2[:dureeTP] = 15
        param2[:quadri] = 2
        param2[:dptCharge] = "INGI2"
        param2[:professeur] = "professeur2"
        param2[:commentaire] = "commentaire2"
        param2[:validite] = 2013
        param2[:import_commentaire] = "import commentaire2"
        param2[:status] = "archive"

        c1 = CoursObject.new(param)
        id1 = c1.save
        assert (id1>=0)

        c2 = CoursObject.new(param2)
        id2 = c2.save
        assert (id2>=0)

        new_c1 = CoursObject.new
        assert (new_c1.load(id1) == true)

        param2[:sigles] = ["s5"] # Autrement l'update ne peut se faire car s4 est déjà attribué

        assert new_c1.update(param2)

        new_c2 = CoursObject.new
        assert (new_c2.load(id2) == true)

        # Ne compare pas les sigles car ils ne peuvent pas être les mêmes dans ce cas
        compare(new_c1,new_c2)

    end

    test "destroy cours" do

        param = {}
        param[:creditsMax] = 4
        param[:creditsMin] = 4
        param[:sigles] = ["s1","s2"]
        param[:dureeCours] = 28.75
        param[:dureeTP] = 28.75
        param[:quadri] = 1

        pml = Pmodule.all.length
        sl = Sigle.all.length
        ccl = CoursContenu.all.length

        c = CoursObject.new(param)
        assert !c.persisted?    
        assert c.save > 0
        assert c.persisted?    
        assert c.destroy
        assert !c.persisted?    

        assert Pmodule.all.length == pml
        assert Sigle.all.length == sl
        assert CoursContenu.all.length == ccl

    end

    def check_not_persisted(param)

        pml = Pmodule.all.length
        sl = Sigle.all.length
        ccl = CoursContenu.all.length

        c = CoursObject.new(param)
        id = c.save()

        assert (id<0)

        assert Pmodule.all.length == pml
        assert Sigle.all.length == sl
        assert CoursContenu.all.length == ccl

    end

    test "transactions on save cours" do

        param = {}
        param[:creditsMax] = -1     # <= invalide
        param[:creditsMin] = -1     # <= invalide
        param[:sigles] = ["s1","s2"]
        param[:dureeCours] = 28.75
        param[:dureeTP] = 28.75
        param[:quadri] = 2

        check_not_persisted(param)

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 5
        param[:sigles] = ["s1"]
        param[:dureeCours] = -1     # <= invalide
        param[:dureeTP] = -1        # <= invalide
        param[:quadri] = 2

        check_not_persisted(param)

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 5
        param[:langue] = "angl"
        param[:sigles] = ["s1"] 
        param[:dureeCours] = 10
        param[:dureeTP] = 10
        param[:quadri] = 2
        param[:validite] = "-1" # <= invalide 

        check_not_persisted(param)

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 5
        param[:langue] = "angl"
        param[:sigles] = ["s1"] 
        param[:dureeCours] = 10
        param[:dureeTP] = 10
        param[:quadri] = 2
        param[:status] = "WRONG" # <= invalide 

        check_not_persisted(param)

    end

    def check_not_changed(id, new_param)

        c = CoursObject.new()
        assert c.load(id)

        c2 = CoursObject.new()
        assert (c2.load(id))

        r = c2.update(new_param)

        assert (r==false)

        c2 = CoursObject.new()
        assert (c2.load(id)) 
        compare(c,c2)

    end

    test "transactions on update cours" do

        param = {}
        param[:creditsMax] = 5
        param[:creditsMin] = 5 
        param[:langue] = "angl"
        param[:sigles] = ["s1","s2"] 
        param[:dureeCours] = 28.75
        param[:dureeTP] = 28.75
        param[:quadri] = 2
        param[:dptCharge] = "INGI"
        param[:commentaire] = "commentaire"

        c = CoursObject.new(param)
        id = c.save()
        assert (id>=0)

        param2 = {}
        param2[:creditsMax] = -1     # <= invalide
        param2[:creditsMin] = -1     # <= invalide
        param2[:langue] = "angl"
        param2[:sigles] = ["s3","s4"] 
        param2[:dureeCours] = 28.75
        param2[:dureeTP] = 28.75
        param2[:quadri] = 2
        param2[:dptCharge] = "INGI"
        param2[:commentaire] = "commentaire"

        check_not_changed(id, param2)

        param2 = {}
        param2[:creditsMax] = 6
        param2[:creditsMin] = 5
        param2[:langue] = "angl"
        param2[:sigles] = ["s5"]
        param2[:dureeCours] = -1     # <= invalide
        param2[:dureeTP] = -1        # <= invalide
        param2[:quadri] = 2
        param2[:dptCharge] = "INGI"
        param2[:commentaire] = "commentaire"

        check_not_changed(id, param2)

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 5
        param[:langue] = "angl"
        param[:sigles] = ["s1"] 
        param[:dureeCours] = 10
        param[:dureeTP] = 10
        param[:quadri] = 2
        param[:validite] = "-1" # <= invalide 

        check_not_changed(id, param2)

        param = {}
        param[:creditsMax] = 6
        param[:creditsMin] = 5
        param[:langue] = "angl"
        param[:sigles] = ["s1"] 
        param[:dureeCours] = 10
        param[:dureeTP] = 10
        param[:quadri] = 2
        param[:status] = "WRONG" # <= invalide 

        check_not_changed(id, param2)

    end

    test "destroy cours but contrainte" do

        param = {}
        param[:creditsMax] = 4
        param[:creditsMin] = 4
        param[:sigles] = ["s1","s2"]
        param[:dureeCours] = 28.75
        param[:dureeTP] = 28.75
        param[:quadri] = 1

        param2 = {}
        param2[:creditsMax] = 4
        param2[:creditsMin] = 4
        param2[:sigles] = ["s3"]
        param2[:dureeCours] = 28.75
        param2[:dureeTP] = 28.75
        param2[:quadri] = 1

        c = CoursObject.new(param)      # sauve c
        assert (c.save>=0)
        c2 = CoursObject.new(param2)    # sauve c2
        assert (c2.save>=0)

        assert (c.destroy)
        assert (c.save>=0)

        param = {}
        param[:target] = "*"
        param[:cond] = "s1"
        param[:effet] = "s3"
        id = ContrainteObject.new(param).save # contrainte interdisant la suppression de c et test de suppression de c
        assert (!c.destroy)
        co = ContrainteObject.new()
        co.load(id)
        co.destroy                            # suppression de la contrainte et test de suppression de c
        assert (c.destroy)

        assert (c.save>=0)                    # resauvegarde de c 

        param = {}
        param[:target] = "*"
        param[:cond] = "s3"
        param[:effet] = "s2"
        id = ContrainteObject.new(param).save # contrainte interdisant la suppression de c et test de suppression de c
        assert (!c.destroy)
        co = ContrainteObject.new()
        co.load(id)
        co.destroy                            # suppression de la contrainte et test de suppression de c
        assert (c.destroy)

        end

        test "load_all" do

        co = default_cours("s")
        assert co.save

        co2 = default_cours("s2")
        assert co2.save

        list = CoursObject.load_all()
        assert list.size == 2
        assert list[0].sigles == "s" || list[0].sigles == "s2"
        assert list[1].sigles == "s" || list[1].sigles == "s2"
        assert list[0].sigles != list[1].sigles

    end

end