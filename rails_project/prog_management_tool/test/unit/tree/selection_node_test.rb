require 'test_helper'

class SelectionNodeTest < ActiveSupport::TestCase

	test "normal case" do 

		n = SelectionNode.new("abc")
		n2 = SelectionNode.new("def", true)

		n.add_child(n2)

		# Test de sélection par défaut et sélection forcée

		assert !n.is_selected?
		assert n2.is_selected?

		# Test de liste sélectionnée

		n.list_selected_nodes.size == 1
		n.list_selected_nodes[0].data == ["def"]

		# Test de liste sélectionnée, après inversion des sélections

		n.select
		n2.deselect

		assert n.is_selected?
		assert !n2.is_selected?

		n.list_selected_nodes.size == 1
		n.list_selected_nodes[0].data == ["abc"]

		# Test de clone

		n3 = n.clone()
		
		assert n3.data == "abc"
		assert n3.is_selected?
		assert n.is_selected?

		n3.deselect

		assert !n3.is_selected?
		assert n.is_selected?

		n3.select
		n.deselect

		assert n3.is_selected?
		assert !n.is_selected?
		
	end

end
