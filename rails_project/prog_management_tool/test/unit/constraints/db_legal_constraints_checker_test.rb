# encoding: utf-8

require 'test_helper'

class DbLegalConstraintsCheckerTest < ActiveSupport::TestCase

	test 'check_prog_master60' do

		eo = default_ensemble("s")
		dlcc = DbLegalConstraintsChecker.new(eo)
		assert dlcc.check_prog_master60
		assert dlcc.report.empty?

		eo.intitule = "master 60"
		assert !dlcc.check_prog_master60
		assert !dlcc.report.empty?

	end

	test 'check_prog_master120' do

		eo = default_ensemble("s")
		dlcc = DbLegalConstraintsChecker.new(eo)
		assert dlcc.check_prog_master120
		assert dlcc.report.empty?

		eo.intitule = "master 120"
		assert !dlcc.check_prog_master120
		assert !dlcc.report.empty?

	end
	
	test 'check_prog_bac' do

		eo = default_ensemble("s")
		dlcc = DbLegalConstraintsChecker.new(eo)
		assert dlcc.check_prog_bac
		assert dlcc.report.empty?

		eo.intitule = "baccalauréat"
		assert !dlcc.check_prog_bac
		assert !dlcc.report.empty?

	end
	
	test 'check_voc_finalite' do

		eo = default_ensemble("s")
		dlcc = DbLegalConstraintsChecker.new(eo)

		eo.intitule = " --FiNAliTe-- "
		eo.creditsMin = $finalite_voc_min - 1
		eo.creditsMax = $finalite_voc_max
		assert !dlcc.check_voc_finalite
		assert !dlcc.report.empty?
		dlcc.report.erase()

		eo.intitule = " --FiNAliTe-- "
		eo.creditsMin = $finalite_voc_min 
		eo.creditsMax = $finalite_voc_max + 1
		assert !dlcc.check_voc_finalite
		assert !dlcc.report.empty?
		dlcc.report.erase()

		eo.intitule = " --iNAliTe-- "
		eo.creditsMin = $finalite_voc_min 
		eo.creditsMax = $finalite_voc_max + 1
		assert dlcc.check_voc_finalite
		assert dlcc.report.empty?

		eo.intitule = " --FiNAliTe-- "
		eo.creditsMin = $finalite_voc_min 
		eo.creditsMax = $finalite_voc_max 
		assert dlcc.check_voc_finalite
		assert dlcc.report.empty?

	end
	
	test 'check_voc_option' do

		eo = default_ensemble("s")
		dlcc = DbLegalConstraintsChecker.new(eo)

		eo.intitule = " --OpTIoN-- "
		eo.creditsMin = $option_voc_min - 1
		eo.creditsMax = $option_voc_max
		assert !dlcc.check_voc_option
		assert !dlcc.report.empty?
		dlcc.report.erase()

		eo.intitule = " --OpTIoN-- "
		eo.creditsMin = $option_voc_min 
		eo.creditsMax = $option_voc_max + 1
		assert !dlcc.check_voc_option
		assert !dlcc.report.empty?
		dlcc.report.erase()

		eo.intitule = " --pTIoN-- "
		eo.creditsMin = $option_voc_min 
		eo.creditsMax = $option_voc_max + 1
		assert dlcc.check_voc_option
		assert dlcc.report.empty?

		eo.intitule = " --OpTIoN-- "
		eo.creditsMin = $option_voc_min 
		eo.creditsMax = $option_voc_max 
		assert dlcc.check_voc_option
		assert dlcc.report.empty?

	end
	
	test 'check_voc_memoire' do

		eo = default_ensemble("s")
		dlcc = DbLegalConstraintsChecker.new(eo)

		eo.intitule = " --MéMOiRe-- "
		eo.creditsMin = $memoire_voc_min - 1
		eo.creditsMax = $memoire_voc_max
		assert !dlcc.check_voc_memoire
		assert !dlcc.report.empty?
		dlcc.report.erase()

		eo.intitule = " --MéMOiRe-- "
		eo.creditsMin = $memoire_voc_min 
		eo.creditsMax = $memoire_voc_max + 1
		assert !dlcc.check_voc_memoire
		assert !dlcc.report.empty?
		dlcc.report.erase()

		eo.intitule = " --éMOiRe-- "
		eo.creditsMin = $memoire_voc_min 
		eo.creditsMax = $memoire_voc_max + 1
		assert dlcc.check_voc_memoire
		assert dlcc.report.empty?

		eo.intitule = " --MéMOiRe-- "
		eo.creditsMin = $memoire_voc_min 
		eo.creditsMax = $memoire_voc_max 
		assert dlcc.check_voc_memoire
		assert dlcc.report.empty?
		
	end
	
	test "check_all" do
		
		eo = default_ensemble("s1")
		dlcc = DbLegalConstraintsChecker.new(eo)
		assert dlcc.check_all()
		assert dlcc.report.empty?

	end


end