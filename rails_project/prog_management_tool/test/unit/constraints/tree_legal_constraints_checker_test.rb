# encoding: utf-8

require 'test_helper'

class TreeLegalConstraintsCheckerTest < ActiveSupport::TestCase
	
	test 'check_prog_master60' do
		
		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)
		assert tlcc.check_prog_master60
		assert tlcc.report.empty?

		eo.intitule = "master 60"
		assert !tlcc.check_prog_master60
		assert !tlcc.report.empty?

	end

	test 'check_prog_master120' do

		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)
		assert tlcc.check_prog_master120
		assert tlcc.report.empty?

		eo.intitule = "master 120"
		assert !tlcc.check_prog_master120
		assert !tlcc.report.empty?

	end
	
	test 'check_prog_bac' do

		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)
		assert tlcc.check_prog_bac
		assert tlcc.report.empty?

		eo.intitule = "baccalauréat"
		assert !tlcc.check_prog_bac
		assert !tlcc.report.empty?

	end

	test 'check_voc_finalite' do

		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)

		eo.intitule = " --FiNAliTe-- "
		eo.creditsMin = $finalite_voc_min - 1
		eo.creditsMax = $finalite_voc_max
		assert !tlcc.check_voc_finalite

		eo.intitule = " --FiNAliTe-- "
		eo.creditsMin = $finalite_voc_min 
		eo.creditsMax = $finalite_voc_max + 1
		assert !tlcc.check_voc_finalite

		eo.intitule = " --iNAliTe-- "
		eo.creditsMin = $finalite_voc_min 
		eo.creditsMax = $finalite_voc_max + 1
		assert tlcc.check_voc_finalite

		eo.intitule = " --FiNAliTe-- "
		eo.creditsMin = $finalite_voc_min 
		eo.creditsMax = $finalite_voc_max 
		assert tlcc.check_voc_finalite

	end
	
	test 'check_voc_option' do

		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)

		eo.intitule = " --OpTIoN-- "
		eo.creditsMin = $option_voc_min - 1
		eo.creditsMax = $option_voc_max
		assert !tlcc.check_voc_option

		eo.intitule = " --OpTIoN-- "
		eo.creditsMin = $option_voc_min 
		eo.creditsMax = $option_voc_max + 1
		assert !tlcc.check_voc_option

		eo.intitule = " --pTIoN-- "
		eo.creditsMin = $option_voc_min 
		eo.creditsMax = $option_voc_max + 1
		assert tlcc.check_voc_option

		eo.intitule = " --OpTIoN-- "
		eo.creditsMin = $option_voc_min 
		eo.creditsMax = $option_voc_max 
		assert tlcc.check_voc_option

	end
	
	test 'check_voc_memoire' do

		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)

		eo.intitule = " --MéMOiRe-- "
		eo.creditsMin = $memoire_voc_min - 1
		eo.creditsMax = $memoire_voc_max
		assert !tlcc.check_voc_memoire
		assert !tlcc.report.empty?
		tlcc.report.erase()

		eo.intitule = " --MéMOiRe-- "
		eo.creditsMin = $memoire_voc_min 
		eo.creditsMax = $memoire_voc_max + 1
		assert !tlcc.check_voc_memoire
		assert !tlcc.report.empty?
		tlcc.report.erase()

		eo.intitule = " --éMOiRe-- "
		eo.creditsMin = $memoire_voc_min 
		eo.creditsMax = $memoire_voc_max + 1
		assert tlcc.check_voc_memoire
		assert tlcc.report.empty?

		eo.intitule = " --MéMOiRe-- "
		eo.creditsMin = $memoire_voc_min 
		eo.creditsMax = $memoire_voc_max 
		assert tlcc.check_voc_memoire
		assert tlcc.report.empty?

	end

	test "check_all" do

		eo = default_ensemble("s")
		n = Node.new(eo)
		tlcc = TreeLegalConstraintsChecker.new(n, n)
		assert tlcc.check_all()
		assert tlcc.report.empty?

	end

end