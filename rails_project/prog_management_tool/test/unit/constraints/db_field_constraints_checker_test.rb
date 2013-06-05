# encoding: utf-8

require 'test_helper'

class DbFieldConstraintsCheckerTest < ActiveSupport::TestCase

	test 'check_fields' do

		eo = default_ensemble("s")

		dfcc = DbFieldConstraintsChecker.new(eo)
		assert dfcc.check_fields()
		assert dfcc.report.empty?

		# Insertion de valeur non valides 

		eo.creditsMin = -1
		assert !dfcc.check_fields()
		assert !dfcc.report.empty?
		dfcc.report.erase()
		eo.creditsMin = 5

		eo.creditsMax = -1
		assert !dfcc.check_fields()
		assert !dfcc.report.empty?
		dfcc.report.erase()
		eo.creditsMax = 5

		eo.langue = "WRONG"
		assert !dfcc.check_fields()
		assert !dfcc.report.empty?
		dfcc.report.erase()
		eo.langue = "fr"

		eo.contenu = "WRONG"		# Contenu non checké ici (check_content_existence le fait)
		assert dfcc.check_fields()
		assert dfcc.report.empty?
		eo.contenu = nil

		eo.validite = -1
		assert !dfcc.check_fields()
		assert !dfcc.report.empty?
		dfcc.report.erase()
		eo.validite = nil

		eo.status = "WRONG"
		assert !dfcc.check_fields()
		assert !dfcc.report.empty?
		dfcc.report.erase()
		eo.status = "actuel"

	end

	test 'check_content_existence' do

		eo1 = default_ensemble("s1")
		eo2 = default_ensemble("s2")
		eo3 = default_ensemble("s3")

		eo1.contenu = "s2 1 true, s3 1-2 false"

		dfcc = DbFieldConstraintsChecker.new(eo1)
		assert !dfcc.check_content_existence()
		assert !dfcc.report.empty?
		dfcc.report.erase()

		assert eo3.save > 0
		assert !dfcc.check_content_existence()
		assert !dfcc.report.empty?
		dfcc.report.erase()

		assert eo2.save > 0
		assert dfcc.check_content_existence()
		assert dfcc.report.empty?

		assert eo1.save > 0
		assert dfcc.check_content_existence()
		assert dfcc.report.empty?
		
	end

	test 'check_content_duplications' do

		eo1 = default_ensemble("s1")
		eo2 = default_ensemble("")
		eo3 = default_ensemble("s4")

		eo2.set_sigles_array(["s2","s3"])

		eo1.contenu = "s2 1 true, s4 1-2 false"

		assert eo2.save() > 0
		assert eo3.save() > 0

		dfcc = DbFieldConstraintsChecker.new(eo1)
		assert dfcc.check_content_duplications()
		assert dfcc.report.empty?

		eo1.contenu = "s2 1 true, s2 1-2 false"
		assert !dfcc.check_content_duplications()
		assert !dfcc.report.empty?
		dfcc.report.erase()

		eo1.contenu = "s3 1 true, s2 1-2 false"
		assert !dfcc.check_content_duplications()
		assert !dfcc.report.empty?
		dfcc.report.erase()

		eo1.contenu = "s2 1 true, s3 1-2 false"
		assert !dfcc.check_content_duplications()
		assert !dfcc.report.empty?
		dfcc.report.erase()
		
	end

	test "check_all" do

		eo = default_ensemble("s")
		dfcc = DbFieldConstraintsChecker.new(eo)
		assert dfcc.check_all()
		assert dfcc.report.empty?

	end


end