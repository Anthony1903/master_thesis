require 'test_helper'

class NodeTest < ActiveSupport::TestCase

	test "normal case" do 

		n = Node.new("abc")
		n2 = Node.new("def")
		
		assert n.data = "abc"
		assert n.children.empty?()

		# Ajout de noeud

		n.add_child(n2)
		assert n.data == "abc"

		# Check du contenu

		assert !n.children.empty?
		assert n.children.size == 1
		assert n.children[0].data == "def"

		# Listes

		assert n.list.sort == ["abc","def"].sort

		assert n.list_nodes.size == 2
		assert n.list_nodes[0].data == "def"
		assert n.list_nodes[1].data == "abc"

		# Suppression de noeud

		assert !n.remove_child(nil)
		assert n.remove_child(n2)

		assert n.children.empty?()

	end

end
