require 'test_helper'

class SelectionTreeTest < ActiveSupport::TestCase

	test "build_tree" do

		eo1 = default_ensemble("s1")
		eo2 = default_ensemble("s2")
		eo3 = default_ensemble("s3")
		eo4 = default_ensemble("s4")
		eo5 = default_ensemble("s5")
		eo6 = default_ensemble("s6")
		eo7 = default_ensemble("s7")

		eo1.contenu = "s2 1 true, s3 1 false"
		eo2.contenu = "s4 1 false, s5 1 true"
		eo3.contenu = "s6 1 true, s7 1 false"

		assert eo7.save() > 0
		assert eo6.save() > 0
		assert eo5.save() > 0
		assert eo4.save() > 0
		assert eo3.save() > 0
		assert eo2.save() > 0
		assert eo1.save() > 0

		n1 = SelectionNode.new(eo1)
		SelectionTree.build_tree(n1)

		# Vérification que seul le contenu obligatoire, dont tous les ancêtres sont obligatoires
		# est sélectionné, ainsi que la racine.

		assert n1.is_selected?
		assert Tree.find_node(n1, "s1").is_selected?
		assert Tree.find_node(n1, "s2").is_selected?
		assert !Tree.find_node(n1, "s3").is_selected?
		assert !Tree.find_node(n1, "s4").is_selected?
		assert Tree.find_node(n1, "s5").is_selected?
		assert !Tree.find_node(n1, "s6").is_selected?
		assert !Tree.find_node(n1, "s7").is_selected?

	end

end