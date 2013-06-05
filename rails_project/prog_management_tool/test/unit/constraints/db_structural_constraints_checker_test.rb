# encoding: utf-8

require 'test_helper'

class DbStructuralConstraintsCheckerTest < ActiveSupport::TestCase
  
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

		assert e2.save > 0
		assert e3.save > 0

		scc = DbStructuralConstraintsChecker.new(e1)
		assert !scc.check_credits_children()
		assert !scc.report.empty?
		scc.report.erase()

		e1.contenu = "s2 1 false, s3 1-2 false"
		assert scc.check_credits_children()
		assert scc.report.empty?

		e1.contenu = "s2 1 true, s3 1-2 false"
		assert scc.check_credits_children()
		assert scc.report.empty?

		e1.contenu = "s2 1 false, s3 1-2 true"
		assert scc.check_credits_children()
		assert scc.report.empty?

		assert e1.save > 0

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

		scc = DbStructuralConstraintsChecker.new(e3)

		assert scc.check_credits_parent() # Si pas dans la DB, parent ok car aucun parent pour le moment
		assert scc.report.empty?

		assert e2.save > 0
		assert e3.save > 0
		assert e1.save > 0

		assert scc.check_credits_parent()
		assert scc.report.empty?

		e3.creditsMin = 4
		e3.creditsMax = 4
		assert !scc.check_credits_parent()
		assert !scc.report.empty?
		scc.report.erase

		e3.creditsMin = 6
		e3.creditsMax = 6
		assert !scc.check_credits_parent()
		assert !scc.report.empty?
		scc.report.erase

		e3.creditsMin = 5
		e3.creditsMax = 5
		assert scc.check_credits_parent()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e1)
		assert scc.check_credits_parent()
		assert scc.report.empty?

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

		e1.contenu = "s2 1 false, s3 1-2 false"
		e2.contenu = "s4 1 false, s5 1-2 false"
		e5.contenu = "s6 1 false, s7 1-2 false"

		assert e7.save > 0
		assert e6.save > 0
		assert e5.save > 0
		assert e4.save > 0
		assert e2.save > 0
		assert e3.save > 0
		assert e1.save > 0

		# Test lorsqu'il n'y a aucun cycle

		scc = DbStructuralConstraintsChecker.new(e1)
		assert scc.check_loops()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e2)
		assert scc.check_loops()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e3)
		assert scc.check_loops()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e4)
		assert scc.check_loops()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e5)
		assert scc.check_loops()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e6)
		assert scc.check_loops()
		assert scc.report.empty?

		scc = DbStructuralConstraintsChecker.new(e7)
		assert scc.check_loops()
		assert scc.report.empty?

		# Test de détection des cycles 

		e4.contenu = "s4 1 false"
		scc = DbStructuralConstraintsChecker.new(e4)
		assert !scc.check_loops()
		assert !scc.report.empty?

		e4.contenu = "s1 1 false"
		scc = DbStructuralConstraintsChecker.new(e4)
		assert !scc.check_loops()
		assert !scc.report.empty?

		e7.contenu = "s2 1 false"
		scc = DbStructuralConstraintsChecker.new(e7)
		assert !scc.check_loops()
		assert !scc.report.empty?

		e8 = default_ensemble("s8")
		e8.contenu = "s2 1 false"
		assert e8.save > 0

		e6.contenu = "s8 1 false"
		scc = DbStructuralConstraintsChecker.new(e6)
		assert !scc.check_loops()
		assert !scc.report.empty?

		e3.contenu = "s5 1 false"
		scc = DbStructuralConstraintsChecker.new(e3)
		assert scc.check_loops()
		assert scc.report.empty?

	end

=begin
	
		 		  19				_ = obligatoire
			/	   | 	  \
		10_		  5<9	 	2<4
    /  /  \  \    /|\        |
   5_ 5    5  5  5 2  4_     3
	
		 		     e1				_ = obligatoire
			/	      | 	  \
		e2		     e3	 	      e4
    /  /  \  \      / | \          |
   e5 c6   c7 c8 c9  c10 c11      c12

=end

	test 'check_strict_credits' do

		hash = build_tree()

		assert DbStructuralConstraintsChecker.check_strict_credits(hash["c12"], 3)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e5"], 5)

		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e4"], 3)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e4"], 0)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e4"], 2)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e4"], 4)
	
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e3"], 6)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e3"], 9)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e3"], 4)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e3"], 5)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e3"], 2)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e3"], 7)
	
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e2"], 5)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e2"], 10)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e2"], 15)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e2"], 20)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e2"], 0)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e2"], 6)
	
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 10)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 13)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 16)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 19)
		assert DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 22)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 0)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 3)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 9)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 15)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 21)
		assert !DbStructuralConstraintsChecker.check_strict_credits(hash["e1"], 23)

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

		e1.contenu = "e2 1 true, e3 1 false, e4 3 false"
		e2.contenu = "e5 1 true, c6 1 false, c7 1 false, c8 1 false"
		e3.contenu = "c9 1 false, c10 1 false, c11 1 true"
		e4.contenu = "c12 1 false"

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

		assert c12.save > 0 
		assert c11.save > 0 
		assert c10.save > 0 
		assert c9.save > 0 
		assert c8.save > 0 
		assert c7.save > 0 
		assert c6.save > 0 
		assert e5.save > 0 
		assert e4.save > 0 
		assert e3.save > 0 
		assert e2.save > 0 
		assert e1.save > 0 

		return {"e1" => e1, "e2" => e2, "e3" => e3, "e4" => e4, "e5" => e5,
				"c6" => c6, "c7" => c7, "c8" => c8, "c9" => c9, "c10" => c10,
				"c11" => c11, "c12" => c12}

	end

	test "check_strict_credits_on_instance" do
		
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

		assert c1.save > 0
		assert c2.save > 0

		dscc = DbStructuralConstraintsChecker.new(e1)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e1.contenu = "c1 1 true, c2 1-2 false"

		dscc = DbStructuralConstraintsChecker.new(e1)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e1.contenu = "c1 1 false, c2 1-2 true"

		dscc = DbStructuralConstraintsChecker.new(e1)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e1.contenu = ""

		dscc = DbStructuralConstraintsChecker.new(e1)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e1.contenu = "c1 1 true, c2 1-2 true"

		dscc = DbStructuralConstraintsChecker.new(e1)
		assert !dscc.check_strict_credits_on_instance()
		assert !dscc.report.empty?

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
		
		assert c11.save > 0
		assert c12.save > 0

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert !dscc.check_strict_credits_on_instance()
		assert !dscc.report.empty?

		e11.creditsMax = 6
		e11.creditsMin = 6

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert !dscc.check_strict_credits_on_instance()
		assert !dscc.report.empty?

		e11.creditsMax = 2
		e11.creditsMin = 2

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert !dscc.check_strict_credits_on_instance()
		assert !dscc.report.empty?

		e11.creditsMax = 7
		e11.creditsMin = 7

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e11.creditsMax = 4
		e11.creditsMin = 4

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e11.creditsMax = 3
		e11.creditsMin = 3

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

		e11.creditsMax = 0
		e11.creditsMin = 0

		dscc = DbStructuralConstraintsChecker.new(e11)
		assert dscc.check_strict_credits_on_instance()
		assert dscc.report.empty?

	end

	test 'make_children_array' do

		e1 = default_ensemble("e1")
		e2 = default_ensemble("e2")
		e3 = default_ensemble("e3")

		e1.contenu = "e2 1 true, e3 1-2 false"

		assert DbStructuralConstraintsChecker.make_children_array(nil) == nil
		assert DbStructuralConstraintsChecker.make_children_array(e1) == :child_miss_error

		assert e2.save > 0
		assert DbStructuralConstraintsChecker.make_children_array(e1) == :child_miss_error

		assert e3.save > 0
		arr = DbStructuralConstraintsChecker.make_children_array(e1)
		
		assert arr[0][0].sigles == "e2"
		assert arr[0][1] == true
		assert arr[1][0].sigles == "e3"
		assert arr[1][1] == false

	end

	test "check_all" do

		eo = default_ensemble("s")
		dscc = DbStructuralConstraintsChecker.new(eo)
		assert dscc.check_all()
		assert dscc.check_all_except_parent()
		assert dscc.report.empty?

	end

end
