require 'test_helper'

class TreeTest < ActiveSupport::TestCase

	test "build_tree" do

		eo1 = default_ensemble("s1")
		eo1.contenu = "s2 1 false, s3 1 false"

		eo2 = default_ensemble("s2")
		eo3 = default_ensemble("s3")
		
		assert eo3.save() > 0
		assert eo2.save() > 0
		assert eo1.save() > 0

		n1 = Node.new(eo1)
		Tree.build_tree(n1)

		assert n1.children.length == 2
		assert n1.children[0].children.length == 0
		assert n1.children[1].children.length == 0

		assert n1.children[0].data.sigles == "s2" || n1.children[1].data.sigles == "s2"
		assert n1.children[0].data.sigles == "s3" || n1.children[1].data.sigles == "s3"
		assert n1.children[0].data.sigles != n1.children[1].data.sigles

	end

	test "find_nodes" do 

		eo1 = default_ensemble("s1")
		eo2 = default_ensemble("s2")
		eo3 = default_ensemble("s3")

		n1 = Node.new(eo1)
		n2 = Node.new(eo2)
		n3 = Node.new(eo3)

		n1.add_child(n2)
		n1.add_child(n3)
		n2.add_child(n3)

		Tree.find_nodes(n1, "s1").size == 1 
		Tree.find_nodes(n1, "s1")[0][0] == nil				# parent
		Tree.find_nodes(n1, "s1")[0][1].data.sigles == "s1" # noeud

		Tree.find_nodes(n1, "s2").size == 1 
		Tree.find_nodes(n1, "s2")[0][0].data.sigles == "s1" # parent
		Tree.find_nodes(n1, "s2")[0][1].data.sigles == "s2" # noeud

		Tree.find_nodes(n1, "s3").size == 2 
		Tree.find_nodes(n1, "s3")[0][0].data.sigles == "s1" # parent
		Tree.find_nodes(n1, "s3")[0][1].data.sigles == "s3" # noeud
		Tree.find_nodes(n1, "s3")[1][0].data.sigles == "s2" # parent
		Tree.find_nodes(n1, "s3")[1][1].data.sigles == "s3" # noeud

		Tree.find_nodes(n1, " ") == :error 
		Tree.find_nodes(n1, "s4") == :error 
		Tree.find_nodes(n1, nil) == :error 

	end

	test "find_node" do 

		eo1 = default_ensemble("s1")
		eo2 = default_ensemble("s2")
		eo3 = default_ensemble("s3")

		n1 = Node.new(eo1)
		n2 = Node.new(eo2)
		n3 = Node.new(eo3)

		n1.add_child(n2)
		n1.add_child(n3)

		Tree.find_node(n1, "s1").data.sigles == "s1"
		Tree.find_node(n1, "s2").data.sigles == "s2"
		Tree.find_node(n1, "s3").data.sigles == "s3"

		Tree.find_node(n1, " ") == :error 
		Tree.find_node(n1, "s4") == :error 
		Tree.find_node(n1, nil) == :error 

	end

	test "remove_node" do 

		eo1 = default_ensemble("s1")
		eo2 = default_ensemble("s2")
		eo3 = default_ensemble("s3")

		n1 = Node.new(eo1)
		n2 = Node.new(eo2)
		n3 = Node.new(eo3)

		n1.add_child(n2)
		n2.add_child(n3)

		# Paramètres incorrectes

		assert n1.children.size == 1
		assert n2.children.size == 1
		assert n3.children.empty?

		assert Tree.remove_node(nil, "s4", n1) == :error
		assert Tree.remove_node(nil, nil, n1) == :error
		assert n1.children.size == 1
		assert n2.children.size == 1
		assert n3.children.empty?

		# Noeuds inexistants

		assert n1.children.size == 1
		assert n2.children.size == 1
		assert n3.children.empty?

		assert !Tree.remove_node("s1", "s4", n1)
		assert !Tree.remove_node("s1", "s3", n1)

		# Suppression des noeuds un à un

		assert Tree.remove_node("s2", "s3", n1)
		assert n1.children.size == 1
		assert n2.children.empty?
		assert n3.children.empty?

		assert Tree.remove_node("s1", "s2", n1)
		assert n1.children.empty?
		assert n2.children.empty?
		assert n3.children.empty?

		assert Tree.remove_node(nil, "s1", n1) == :error

		# Vérification que le noeud supprimé est le bon

		n1.add_child(n2)
		n1.add_child(n3)
		
		assert n1.children.size == 2
		
		assert Tree.remove_node("s1", "s2", n1)
		assert n1.data.sigles == "s1"
		assert n1.children.size == 1
		assert n1.children[0].data.sigles == "s3"

	end

end