require 'test_helper'

class SelectionConstraintsCheckerTest < ActiveSupport::TestCase

	test 'check_credits' do

		# Avec credits strictements égaux

		eo = default_ensemble("eo1")
		co1 = default_cours("co1")
		co2 = default_cours("co2")

		eo.creditsMin = 5
		eo.creditsMax = 5

		co1.creditsMin = 5
		co1.creditsMax = 5

		co2.creditsMin = 5
		co2.creditsMax = 5

		eo.contenu = "co1 1 false, co2 1 false"

		n1 = SelectionNode.new(eo)
		n2 = SelectionNode.new(co1)
		n3 = SelectionNode.new(co2)

		n1.add_child(n2)
		n1.add_child(n3)

		scc = SelectionConstraintsChecker.new(n1)
		assert scc.check_credits
		assert scc.report.empty?

		n1.select()
		assert !scc.check_credits
		assert !scc.report.empty?
		scc.report.erase

		n2.select
		assert scc.check_credits
		assert scc.report.empty?

		n3.select
		assert !scc.check_credits
		assert !scc.report.empty?
		scc.report.erase

		n2.deselect
		assert scc.check_credits
		assert scc.report.empty?

		n3.deselect
		assert !scc.check_credits
		assert !scc.report.empty?
		scc.report.erase

		n1.deselect
		n2.select
		n3.select
		assert scc.check_credits
		assert scc.report.empty?

		# Avec credits dans un interval
		
		eo = default_ensemble("eo1")
		co1 = default_cours("co1")
		co2 = default_cours("co2")

		eo.creditsMin = 3
		eo.creditsMax = 6

		co1.creditsMin = 4
		co1.creditsMax = 4

		co2.creditsMin = 5
		co2.creditsMax = 5

		eo.contenu = "co1 1 false, co2 1 false"

		n1 = SelectionNode.new(eo)
		n2 = SelectionNode.new(co1)
		n3 = SelectionNode.new(co2)

		n1.add_child(n2)
		n1.add_child(n3)

		scc = SelectionConstraintsChecker.new(n1)
		assert scc.check_credits
		assert scc.report.empty?

		n1.select()
		assert !scc.check_credits
		assert !scc.report.empty?
		scc.report.erase

		n2.select
		assert scc.check_credits
		assert scc.report.empty?

		n3.select
		assert !scc.check_credits
		assert !scc.report.empty?
		scc.report.erase

		n2.deselect
		assert scc.check_credits
		assert scc.report.empty?

		n3.deselect
		assert !scc.check_credits
		assert !scc.report.empty?
		scc.report.erase

		n1.deselect
		n2.select
		n3.select
		assert scc.check_credits
		assert scc.report.empty?

		# Cas de l'ensemble sans contenu

		eo.contenu = nil
		n1 = SelectionNode.new(eo)
		n1.select
		scc = SelectionConstraintsChecker.new(n1)
		assert scc.check_credits

	end

	test 'check_mandatory_content' do

		eo = default_ensemble("eo1")
		co1 = default_cours("co1")
		co2 = default_cours("co2")

		eo.creditsMin = 5
		eo.creditsMax = 5

		co1.creditsMin = 5
		co1.creditsMax = 5

		co2.creditsMin = 5
		co2.creditsMax = 5

		eo.contenu = "co1 1 true, co2 1 false"

		n1 = SelectionNode.new(eo)
		n2 = SelectionNode.new(co1)
		n3 = SelectionNode.new(co2)

		n1.add_child(n2)
		n1.add_child(n3)

		scc = SelectionConstraintsChecker.new(n1)
		assert scc.check_mandatory_content
		assert scc.report.empty?

		n1.select()
		assert !scc.check_mandatory_content
		assert !scc.report.empty?
		scc.report.erase

		n2.select
		assert scc.check_mandatory_content
		assert scc.report.empty?

		n3.select
		assert scc.check_mandatory_content
		assert scc.report.empty?
		scc.report.erase

		n2.deselect
		assert !scc.check_mandatory_content
		assert !scc.report.empty?

		n3.deselect
		assert !scc.check_mandatory_content
		assert !scc.report.empty?
		scc.report.erase

		n1.deselect
		n2.select
		n3.select
		assert scc.check_mandatory_content
		assert scc.report.empty?

	end

	test 'check_and_apply_choice_constraints' do
		
		e1 = default_ensemble("s1")
		e1.creditsMin = 5
		e1.creditsMax = 5
		e1.contenu = "s2 1 false, s3 1-2 false"

		c1 = default_cours("s2")
		c1.creditsMin = 5
		c1.creditsMax = 5

		c2 = default_cours("s3")
		c2.creditsMin = 5
		c2.creditsMax = 5

		assert c2.save() > 0
		assert c1.save() > 0
		assert e1.save() > 0

		n1 = SelectionNode.new(e1)
		n2 = SelectionNode.new(c1)
		n3 = SelectionNode.new(c2)

		n1.add_child(n2)
		n1.add_child(n3)

		# Simple vérification que la sélection de s1 enclenche la contrainte et donc remplis le rapport

		co = create_constraints_object("*", "s1", "E(s2)")
		assert co.save > 0

		scc = SelectionConstraintsChecker.new(n1, n1)
		assert scc.report.list.size == 0
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size == 0
		n1.select
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size > 0
		n1.deselect
		assert co.destroy

		co = create_constraints_object("*", "s1", "T(s2)")
		assert co.save > 0

		scc = SelectionConstraintsChecker.new(n1, n1)
		assert scc.report.list.size == 0
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size == 0
		n1.select
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size > 0
		n1.deselect
		assert co.destroy

		co = create_constraints_object("*", "s1", "C(s2)")
		assert co.save > 0

		scc = SelectionConstraintsChecker.new(n1, n1)
		assert scc.report.list.size == 0
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size == 0
		n1.select
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size > 0
		n1.deselect
		assert co.destroy

		co = create_constraints_object("*", "s1", "!s2")
		assert co.save > 0

		scc = SelectionConstraintsChecker.new(n1, n1)
		assert scc.report.list.size == 0
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size == 0
		n1.select
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size > 0
		n1.deselect
		assert co.destroy

		# Cas de M[ s1 > s2 ]

=begin
			s4					s4
			|		 =>	 		|
			s1		 =>	  		s5
		/		\	 =>		/		\
	  s2		s3		  s6		 s7

=end

		e2 = default_ensemble("s4")
		e2.creditsMin = 5
		e2.creditsMax = 5
		e2.contenu = "s1 1 true"
		
		e3 = default_ensemble("s5")
		e3.creditsMin = 5
		e3.creditsMax = 5
		e3.contenu = "s6 1 false, s7 1-2 false"

		c3 = default_cours("s6")
		c3.creditsMin = 5
		c3.creditsMax = 5

		c4 = default_cours("s7")
		c4.creditsMin = 5
		c4.creditsMax = 5

		assert c4.save() > 0
		assert c3.save() > 0
		assert e3.save() > 0
		assert e2.save() > 0

		n0 = SelectionNode.new(e2)
		n0.add_child(n1)

		co = create_constraints_object("*", "s4", "M[s1 > s5]")
		assert co.save > 0

		# Cas ou la substitution ne doit pas être faite

		scc = SelectionConstraintsChecker.new(n0, n0)
		assert scc.report.list.size == 0
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size == 0

		assert n0.children.size == 1
		assert n0.children[0].data.sigles == "s1"

		# Cas ou la substitution doit être être faite

		n0.select
		scc.check_and_apply_choice_constraints
		assert scc.report.list.size > 0

		# Vérifie que le noeud a été substitué
		assert n0.children.size == 1
		assert n0.children[0].data.sigles == "s5"		

		# Vérifie que les enfants ont été adaptés
		assert n0.children[0].children.size == 2
		assert n0.children[0].children[0].data.sigles == "s6" || n0.children[0].children[0].data.sigles == "s7"
		assert n0.children[0].children[1].data.sigles == "s6" || n0.children[0].children[1].data.sigles == "s7"
		assert n0.children[0].children[0].data.sigles != n0.children[0].children[1].data.sigles

	end

	test "check_all" do 

		eo = default_ensemble("eo")
		n = SelectionNode.new(eo)
		scc = SelectionConstraintsChecker.new(n, n)
		assert scc.check_all()
		assert scc.report.empty?

	end

end