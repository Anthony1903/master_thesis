require 'test_helper'

class StructuralConstraintsCheckerTest < ActiveSupport::TestCase

	test "list_values" do
		
		assert StructuralConstraintsChecker.list_values(0, 5) == [0,1,2,3,4,5]
		assert StructuralConstraintsChecker.list_values(6, 5) == nil
		assert StructuralConstraintsChecker.list_values(nil, 5) == nil
		assert StructuralConstraintsChecker.list_values(5, nil) == nil

	end

	test "product" do

		assert StructuralConstraintsChecker.product(nil, [1,2,3]) == nil
		assert StructuralConstraintsChecker.product([1,2,3], nil) == nil
		assert StructuralConstraintsChecker.product([1], [2]) == [[1,2]]
		assert StructuralConstraintsChecker.product([1,2,3], [1]).sort == [[1,1],[2,1],[3,1]].sort
		assert StructuralConstraintsChecker.product([1],[1,2,3]).sort == [[1,1],[1,2],[1,3]].sort
		assert StructuralConstraintsChecker.product([1,2], [3,4]).sort == [[1,3],[1,4],[2,3],[2,4]].sort

	end

	test "filter_on_sum" do

		assert StructuralConstraintsChecker.filter_on_sum(nil , 10) == nil
		assert StructuralConstraintsChecker.filter_on_sum([] , nil) == nil
		assert StructuralConstraintsChecker.filter_on_sum([] , 5) == []
		assert StructuralConstraintsChecker.filter_on_sum([[1]] , 5) == []
		assert StructuralConstraintsChecker.filter_on_sum([[5]] , 5) == [[5]]
		assert StructuralConstraintsChecker.filter_on_sum([[1,2,3]] , 10) == []
		assert StructuralConstraintsChecker.filter_on_sum([[1,2,3,4]] , 10).sort == [[1,2,3,4]]
		assert StructuralConstraintsChecker.filter_on_sum([[1,2,3],[2,3],[3,3],[1,1,1,3],[6,-6],[6,-6,6]], 6).sort == [[1,2,3],[3,3],[1,1,1,3],[6,-6,6]].sort

	end	

	test "all_combinations_aux" do

		assert StructuralConstraintsChecker.all_combinations_aux(nil) == nil
		assert StructuralConstraintsChecker.all_combinations_aux([]) == nil
		assert StructuralConstraintsChecker.all_combinations_aux([[1,2,true]]).sort == [[1],[2]].sort
		assert StructuralConstraintsChecker.all_combinations_aux([[1,2,false]]).sort == [[0],[1],[2]].sort
		assert StructuralConstraintsChecker.all_combinations_aux([[1,2,false], [3,4,true]]).sort == [[0, 3], [0, 4], [1, 3], [1, 4], [2, 3], [2, 4]].sort
		assert StructuralConstraintsChecker.all_combinations_aux([[1,2,false]]).sort == [[0],[1],[2]].sort

	end

	test "all_combinations" do

		e1 = default_ensemble("e1")
		e2 = default_ensemble("e2")

		e1.creditsMin = 1
		e1.creditsMax = 2

		e2.creditsMin = 3
		e2.creditsMax = 4

		contenu_arr = [[e1, false],[e2, true]]
		assert StructuralConstraintsChecker.all_combinations(nil) == nil
		assert StructuralConstraintsChecker.all_combinations([]) == []
		assert StructuralConstraintsChecker.all_combinations(contenu_arr).sort == [[0, 3], [0, 4], [1, 3], [1, 4], [2, 3], [2, 4]].sort

		contenu_arr = [[e1, false]]
		assert StructuralConstraintsChecker.all_combinations(contenu_arr).sort == [[0],[1],[2]].sort

	end

end