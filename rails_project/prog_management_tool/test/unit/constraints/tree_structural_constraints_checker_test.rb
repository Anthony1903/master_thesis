# encoding: utf-8

require 'test_helper'

class TreeStructuralConstraintsCheckerTest < ActiveSupport::TestCase

    test 'check_credits_children' do 

        e1 = default_ensemble("s1")
        e1.creditsMin = 5
        e1.creditsMax = 5
        e1.contenu = "s2 1 true, s3 1-2 true"

        e2 = default_ensemble("s2")
        e2.creditsMin = 5
        e2.creditsMax = 5
        e2.contenu = nil

        e3 = default_ensemble("s3")
        e3.creditsMin = 5
        e3.creditsMax = 5
        e3.contenu = nil

        n1 = Node.new(e1)
        n2 = Node.new(e2)
        n3 = Node.new(e3)

        n1.add_child(n2)
        n1.add_child(n3)

        tcc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert !tcc.check_credits_children()
        assert !tcc.report.empty?

        tcc.report.erase()

        e1.contenu = "s2 1 false, s3 1-2 false"
        assert tcc.check_credits_children()
        assert tcc.report.empty?

        e1.contenu = "s2 1 true, s3 1-2 false"
        assert tcc.check_credits_children()
        assert tcc.report.empty?

        e1.contenu = "s2 1 false, s3 1-2 true"
        assert tcc.check_credits_children()
        assert tcc.report.empty?

    end

    test 'check_credits_parent' do 
        
        e1 = default_ensemble("s1")
        e1.creditsMin = 10
        e1.creditsMax = 10
        e1.contenu = "s2 1 true, s3 1-2 true"

        e2 = default_ensemble("s2")
        e2.creditsMin = 5
        e2.creditsMax = 5
        e2.contenu = nil

        e3 = default_ensemble("s3")
        e3.creditsMin = 5
        e3.creditsMax = 5
        e3.contenu = nil

        n1 = Node.new(e1)
        n2 = Node.new(e2)
        n3 = Node.new(e3)

        n1.add_child(n2)
        n1.add_child(n3)

        tcc = TreeStructuralConstraintsChecker.new(n3, n1)
        assert tcc.check_credits_parent()
        assert tcc.report.empty?

        e3.creditsMin = 4
        e3.creditsMax = 4
        assert !tcc.check_credits_parent()
        assert !tcc.report.empty?
        tcc.report.erase

        e3.creditsMin = 6
        e3.creditsMax = 6
        assert !tcc.check_credits_parent()
        assert !tcc.report.empty?
        tcc.report.erase

        e3.creditsMin = 5
        e3.creditsMax = 5
        assert tcc.check_credits_parent()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tcc.check_credits_parent()
        assert tcc.report.empty?
        
    end

=begin
    Crée l'arbre suivant et tente d'y ajouter des cycles
                            mod1
                       /           \
                mod2                   mod3
             /        \   
          mod4        mod5    
                    /      \
                  mod6     mod7
=end

    test 'check_loops' do 

        e1 = default_ensemble("s1")
        e2 = default_ensemble("s2")
        e3 = default_ensemble("s3")
        e4 = default_ensemble("s4")
        e5 = default_ensemble("s5")
        e6 = default_ensemble("s6")
        e7 = default_ensemble("s7")

        n1 = Node.new(e1)
        n2 = Node.new(e2)
        n3 = Node.new(e3)
        n4 = Node.new(e4)
        n5 = Node.new(e5)
        n6 = Node.new(e6)
        n7 = Node.new(e7)

        e1.contenu = "s2 1 false, s3 1-2 false"
        n1.add_child(n2)
        n1.add_child(n3)

        e2.contenu = "s4 1 false, s5 1-2 false"
        n2.add_child(n4)
        n2.add_child(n5)

        e5.contenu = "s6 1 false, s7 1-2 false"
        n5.add_child(n6)
        n5.add_child(n7)

        # Test lorsqu'il n'y a aucun cycle

        tcc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n2, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n3, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n4, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n5, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n6, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        tcc = TreeStructuralConstraintsChecker.new(n7, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?

        # Test de détection des cycles 

        e4.contenu = "s4 1 false"
        n4.add_child(n4)
        tcc = TreeStructuralConstraintsChecker.new(n4, n1)
        assert !tcc.check_loops()
        assert !tcc.report.empty?
        n4.remove_child(n4)
        e4.contenu = nil

        e4.contenu = "s1 1 false"
        n4.add_child(n1)
        tcc = TreeStructuralConstraintsChecker.new(n4, n1)
        assert !tcc.check_loops()
        assert !tcc.report.empty?
        assert n4.remove_child(n1)
        e4.contenu = nil

        e7.contenu = "s2 1 false"
        n7.add_child(n2)
        tcc = TreeStructuralConstraintsChecker.new(n2, n1)
        assert !tcc.check_loops()
        assert !tcc.report.empty?
        assert n7.remove_child(n2)
        e7.contenu = nil

        e8 = default_ensemble("s8")
        e8.contenu = "s2 1 false"
        n8 = Node.new(e8)
        n8.add_child(n2)

        e6.contenu = "s8 1 false"
        n6.add_child(n8)
        tcc = TreeStructuralConstraintsChecker.new(n6, n1)
        assert !tcc.check_loops()
        assert !tcc.report.empty?
        assert n6.remove_child(n8)
        e6.contenu = nil

        e3.contenu = "s5 1 false"
        n3.add_child(n5)
        tcc = TreeStructuralConstraintsChecker.new(n3, n1)
        assert tcc.check_loops()
        assert tcc.report.empty?
        assert n3.remove_child(n5)
        e3.contenu = nil

    end

=begin
    
                  20                _ = obligatoire
            /      |      \
        10_       5<9       2<4
    /  /  \  \    /|\        |
   5_ 5    5  5  5 2  4_     3
    
                     e1             _ = obligatoire
            /         |       \
        e2           e3           e4
    /  /  \  \      / | \          |
   e5 c6   c7 c8 c9  c10 c11      c12

=end
    
    def tree_to_string_arr(node)
        res = []
        node.children.each do |child|
            res << tree_to_string_arr(child)
        end
        str = node.data.sigles + " "
        str += node.data.creditsMax.to_s + " "
        str += node.data.creditsMax.to_s + " "
        str += node.to_s + " - "
        res << str
        return res
    end

    test 'check_strict_credits test' do

        hash = build_tree()

        root = hash["n1"]

        arr = tree_to_string_arr(root)

        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n12"], 3, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n5"], 5, root)

        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n4"], 3, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n4"], 0, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n4"], 2, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n4"], 4, root)

        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n3"], 6, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n3"], 9, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n3"], 4, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n3"], 5, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n3"], 2, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n3"], 7, root)

        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n2"], 5, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n2"], 10, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n2"], 15, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n2"], 20, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n2"], 0, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n2"], 6, root)

        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 10, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 13, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 16, root)
        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 19, root)

        assert TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 22, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 0, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 3, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 9, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 15, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 21, root)
        assert !TreeStructuralConstraintsChecker.check_strict_credits(hash["n1"], 23, root)

        arr2 = tree_to_string_arr(root)
        assert arr == arr2

    end

    def build_tree()

        e1 = default_ensemble("e1")
        e2 = default_ensemble("e2")
        e3 = default_ensemble("e3")
        e4 = default_ensemble("e4")
        e5 = default_ensemble("e5")
        c6 = default_cours("c6")
        c7 = default_cours("c7")
        c8 = default_cours("c8")
        c9 = default_cours("c9")
        c10 = default_cours("c10")
        c11 = default_cours("c11")
        c12 = default_cours("c12")

        n1 = Node.new(e1)
        n2 = Node.new(e2)
        n3 = Node.new(e3)
        n4 = Node.new(e4)
        n5 = Node.new(e5)
        n6 = Node.new(c6)
        n7 = Node.new(c7)
        n8 = Node.new(c8)
        n9 = Node.new(c9)
        n10 = Node.new(c10)
        n11 = Node.new(c11)
        n12 = Node.new(c12)

        e1.contenu = "e2 1 true, e3 1 false, e4 3 false"
        e2.contenu = "e5 1 true, c6 1 false, c7 1 false, c8 1 false"
        e3.contenu = "c9 1 false, c10 1 false, c11 1 true"
        e4.contenu = "c12 1 false"

        n1.add_child(n2)
        n1.add_child(n3)
        n1.add_child(n4)

        n2.add_child(n5)
        n2.add_child(n6)
        n2.add_child(n7)
        n2.add_child(n8)

        n3.add_child(n9)
        n3.add_child(n10)
        n3.add_child(n11)

        n4.add_child(n12)

        e1.creditsMin=19
        e1.creditsMax=19

        e2.creditsMin=10
        e2.creditsMax=10

        e3.creditsMin=5
        e3.creditsMax=9

        e4.creditsMin=2
        e4.creditsMax=4

        e5.creditsMin=5
        e5.creditsMax=5

        c6.creditsMin=5
        c6.creditsMax=5

        c7.creditsMin=5
        c7.creditsMax=5

        c8.creditsMin=5
        c8.creditsMax=5

        c9.creditsMin=5
        c9.creditsMax=5

        c10.creditsMin=2
        c10.creditsMax=2

        c11.creditsMin=4
        c11.creditsMax=4

        c12.creditsMin=3
        c12.creditsMax=3

        tcc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tcc.check_all
        tcc = TreeStructuralConstraintsChecker.new(n2, n2)
        assert tcc.check_all
        tcc = TreeStructuralConstraintsChecker.new(n3, n3)
        assert tcc.check_all
        tcc = TreeStructuralConstraintsChecker.new(n4, n4)
        assert tcc.check_all

        return {"n1" => n1, "n2" => n2, "n3" => n3, "n4" => n4, "n5" => n5,
                "n6" => n6, "n7" => n7, "n8" => n8, "n9" => n9, "n10" => n10,
                "n11" => n11, "n12" => n12}

    end

    test "check_strict_credits_on_instance test" do

        # Cas simple
        
        e1 = default_ensemble("e1")
        c1 = default_cours("c1")
        c2 = default_cours("c2")

        e1.contenu = "c1 1 false, c2 1-2 false"
        e1.creditsMax = 5
        e1.creditsMin = 5

        c1.creditsMax = 5
        c1.creditsMin = 5

        c2.creditsMax = 5
        c2.creditsMin = 5

        n1 = Node.new(e1)
        n2 = Node.new(c1)
        n3 = Node.new(c2)

        n1.add_child(n2)
        n1.add_child(n3)

        e1.contenu = "c1 1 false, c2 1-2 false"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e1.contenu = "c1 1 true, c2 1-2 false"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e1.contenu = "c1 1 false, c2 1-2 true"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e1.contenu = ""

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e1.contenu = "c1 1 true, c2 1-2 true"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert !tscc.check_strict_credits_on_instance()
        assert !tscc.report.empty?

        # Cas plus complexe

        e11 = default_ensemble("e11")
        c11 = default_cours("c11")
        c12 = default_cours("c12")

        e11.contenu = "c11 1 false, c12 1-2 false"
        
        e11.creditsMax = 5
        e11.creditsMin = 5

        c11.creditsMax = 4 
        c11.creditsMin = 4

        c12.creditsMax = 3
        c12.creditsMin = 3

        n1 = Node.new(e11)
        n2 = Node.new(c11)
        n3 = Node.new(c12)

        n1.add_child(n2)
        n1.add_child(n3)

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert !tscc.check_strict_credits_on_instance()
        assert !tscc.report.empty?

        e11.creditsMax = "6"
        e11.creditsMin = "6"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert !tscc.check_strict_credits_on_instance()
        assert !tscc.report.empty?

        e11.creditsMax = "2"
        e11.creditsMin = "2"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert !tscc.check_strict_credits_on_instance()
        assert !tscc.report.empty?

        e11.creditsMax = "7"
        e11.creditsMin = "7"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e11.creditsMax = "4"
        e11.creditsMin = "4"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e11.creditsMax = "3"
        e11.creditsMin = "3"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

        e11.creditsMax = "0"
        e11.creditsMin = "0"

        tscc = TreeStructuralConstraintsChecker.new(n1, n1)
        assert tscc.check_strict_credits_on_instance()
        assert tscc.report.empty?

    end

    test 'make_children_array test' do

        e1 = default_ensemble("e1")
        e2 = default_ensemble("e2")
        e3 = default_ensemble("e3")

        e1.contenu = "e2 1 true, e3 1-2 false"

        n1 = Node.new(e1)
        n2 = Node.new(e2)
        n3 = Node.new(e3)

        assert TreeStructuralConstraintsChecker.make_children_array(nil) == [nil, nil]
        assert TreeStructuralConstraintsChecker.make_children_array(n1) == [:child_miss_error, nil]
        
        n1.add_child(n2)
        assert TreeStructuralConstraintsChecker.make_children_array(n1) == [:child_miss_error, nil]
        
        n1.add_child(n3)
        c_arr, n_arr = TreeStructuralConstraintsChecker.make_children_array(n1)
        assert c_arr[0][0].sigles == "e2"
        assert c_arr[0][1] == true
        assert c_arr[1][0].sigles == "e3"
        assert c_arr[1][1] == false

        assert c_arr[0][0] == n_arr[0].data
        assert c_arr[1][0] == n_arr[1].data

    end

    test "check_all" do

        eo = default_ensemble("s")
        n = Node.new(eo)
        tscc = TreeStructuralConstraintsChecker.new(n, n)
        assert tscc.check_all()
        assert tscc.check_all_except_parent()
        assert tscc.report.empty?

    end

end
