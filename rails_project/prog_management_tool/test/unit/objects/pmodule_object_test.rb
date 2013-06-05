# encoding: utf-8

require 'test_helper'

class PmoduleObjectTest < ActiveSupport::TestCase

    def add_constr_and_check(sigle, mod, value)

        param = {}
        param[:target] = "*"
        param[:cond] = sigle
        param[:effet] = sigle
        c = ContrainteObject.new(param)
        assert c.save

        report = Report.new()

        assert mod.can_destroy_recursively?(report) == value
        assert report.empty? == value
        
        assert c.destroy
        
    end

    test "can_destroy_recursively" do

        report = Report.new()                           # Ajout d'un ensemble et vérification qu'il est supprimable
        e1 = default_ensemble("e1")
        assert e1.save()
        assert e1.can_destroy_recursively?(report)
        assert report.empty?

        c1 = default_cours("c1")                        # Ajout d'un cours et vérification qu'il est supprimable
        assert c1.save()
        assert c1.can_destroy_recursively?(report)
        assert report.empty?

        e2 = default_ensemble("e2")                     # Ajout d'un ensemble contenant les deux modules, et vérification qu'il est supprimable
        e2.contenu = "c1 1 true, e1 1-2 false"
        assert e2.save()
        assert e2.can_destroy_recursively?(report)
        assert report.empty?

        assert !c1.can_destroy_recursively?(report)     # Verification que le contenu n'est plus supprimable
        assert !report.empty?
        report.erase()

        assert !e1.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        # Cas complet

        e1 = default_ensemble("s1")
        e2 = default_ensemble("s2")
        c3 = default_cours("s3")
        c4 = default_cours("s4")
        e5 = default_ensemble("s5")
        c6 = default_cours("s6")
        c7 = default_cours("s7")

        e1.contenu = "s2 1 false, s3 1-2 false"
        e2.contenu = "s4 1 false, s5 1-2 false"
        e5.contenu = "s6 1 false, s7 1-2 false"

        assert c7.save > 0
        assert c6.save > 0
        assert e5.save > 0
        assert c4.save > 0
        assert c3.save > 0
        assert e2.save > 0
        assert e1.save > 0

        assert e1.can_destroy_recursively?(report)
        assert report.empty?
        report.erase()

        assert !e2.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        assert !c3.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()
        
        assert !c4.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()
        
        assert !e5.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()
        
        assert !c6.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()
        
        assert !c7.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()
        
    end

    test "destroy_recursively" do

        report = Report.new()                           # Ajout d'un ensemble et suppression
        e1 = default_ensemble("e1")
        assert e1.save()
        assert e1.destroy_recursively(report)
        assert report.empty?

        c1 = default_cours("c1")                        # Ajout d'un cours et suppression
        assert c1.save()
        assert c1.destroy_recursively(report)
        assert report.empty?

        count = Pmodule.all.length()

        e1.save()
        c1.save()

        e2 = default_ensemble("e2")                     # Ajout d'un ensemble contenant deux modules
        e2.contenu = "c1 1 true, e1 1-2 false"
        assert e2.save()     

        assert !c1.destroy_recursively(report)          # Verification que le contenu n'est plus supprimable
        assert !report.empty?
        report.erase()

        assert !e1.destroy_recursively(report)       
        assert !report.empty?
        report.erase()

        assert e2.destroy_recursively(report)           # Suppression du conteneur
        assert report.empty?

        assert Pmodule.all.length() == count            # Vérification que tout a bien été supprimé

        # Cas complet

        count = Pmodule.all.length()

        e1 = default_ensemble("s1")
        e2 = default_ensemble("s2")
        c3 = default_cours("s3")
        c4 = default_cours("s4")
        e5 = default_ensemble("s5")
        c6 = default_cours("s6")
        c7 = default_cours("s7")

        e1.contenu = "s2 1 false, s3 1-2 false"
        e2.contenu = "s4 1 false, s5 1-2 false"
        e5.contenu = "s6 1 false, s7 1-2 false"

        assert c7.save > 0
        assert c6.save > 0
        assert e5.save > 0
        assert c4.save > 0
        assert c3.save > 0
        assert e2.save > 0
        assert e1.save > 0

        assert !e2.destroy_recursively(report)
        assert !report.empty?
        report.erase()

        assert !c3.destroy_recursively(report)
        assert !report.empty?
        report.erase()
        
        assert !c4.destroy_recursively(report)
        assert !report.empty?
        report.erase()
        
        assert !e5.destroy_recursively(report)
        assert !report.empty?
        report.erase()
        
        assert !c6.destroy_recursively(report)
        assert !report.empty?
        report.erase()
        
        assert !c7.destroy_recursively(report)
        assert !report.empty?
        report.erase()

        assert e1.destroy_recursively(report)
        assert report.empty?
        report.erase()

        assert Pmodule.all.length() == count            # Vérification que tout a bien été supprimé

    end

    test "can_destroy_recursively and contraintes" do
 
        report = Report.new()                           # Ajout d'un ensemble et vérification qu'il est supprimable
        e1 = default_ensemble("e1")
        assert e1.save()
        assert e1.can_destroy_recursively?(report)
        assert report.empty?

        c1 = default_cours("c1")                        # Ajout d'un cours et vérification qu'il est supprimable
        assert c1.save()
        assert c1.can_destroy_recursively?(report)
        assert report.empty?

        param = {}
        param[:target] = "*"
        param[:cond] = "e1"
        param[:effet] = "c1"
        c = ContrainteObject.new(param)
        assert c.save

        assert !e1.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        assert !c1.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        assert c.destroy()

        assert e1.can_destroy_recursively?(report)
        assert report.empty?

        assert c1.can_destroy_recursively?(report)
        assert report.empty?

        param = {}
        param[:target] = "e1"
        param[:cond] = "c1"
        param[:effet] = "c1"
        c = ContrainteObject.new(param)
        assert c.save

        assert !c1.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        assert !e1.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        e2 = default_ensemble("e2")                     # Ajout d'un ensemble contenant les deux modules, et vérification qu'il est supprimable
        e2.contenu = "c1 1 true, e1 1-2 false"
        assert e2.save()
        assert !e2.can_destroy_recursively?(report)
        assert !report.empty?
        report.erase()

        assert c.destroy

        assert e2.can_destroy_recursively?(report)
        assert report.empty?

         # Cas complet

        e1 = default_ensemble("s1")
        e2 = default_ensemble("s2")
        c3 = default_cours("s3")
        c4 = default_cours("s4")
        e5 = default_ensemble("s5")
        c6 = default_cours("s6")
        c7 = default_cours("s7")

        e1.contenu = "s2 1 false, s3 1-2 false"
        e2.contenu = "s4 1 false, s5 1-2 false"
        e5.contenu = "s6 1 false, s7 1-2 false"

        assert c7.save > 0
        assert c6.save > 0
        assert e5.save > 0
        assert c4.save > 0
        assert c3.save > 0
        assert e2.save > 0
        assert e1.save > 0

        assert e1.can_destroy_recursively?(report)
        assert report.empty?

        add_constr_and_check("s1", e1, false)
        add_constr_and_check("s1", e2, false)
        add_constr_and_check("s1", c3, false)
        add_constr_and_check("s1", c4, false)
        add_constr_and_check("s1", e5, false)
        add_constr_and_check("s1", c6, false)
        add_constr_and_check("s1", c7, false)
        
        assert e1.can_destroy_recursively?(report)
        assert report.empty?

    end

    test "graphs" do 

        c = default_cours("c")            

        e = default_ensemble("e")   
        e.contenu = "c 1 false"

        assert c.save > 0
        assert e.save > 0

        assert c.build_graph
        assert c.build_complete_graph

        assert e.build_graph
        assert e.build_complete_graph

    end

end
