# encoding: utf-8

require 'test_helper'

class TreeFieldConstraintsCheckerTest < ActiveSupport::TestCase

    test 'check_fields' do

        eo = default_ensemble("s")
        n = Node.new(eo)

        tfcc = TreeFieldConstraintsChecker.new(n, n)
        assert tfcc.check_fields()
        assert tfcc.report.empty?

        eo.creditsMin = -1
        assert !tfcc.check_fields()
        assert !tfcc.report.empty?
        tfcc.report.erase()
        eo.creditsMin = 5

        eo.creditsMax = -1
        assert !tfcc.check_fields()
        assert !tfcc.report.empty?
        tfcc.report.erase()
        eo.creditsMax = 5

        eo.langue = "WRONG"
        assert !tfcc.check_fields()
        assert !tfcc.report.empty?
        tfcc.report.erase()
        eo.langue = "fr"

        eo.contenu = "WRONG"        # Contenu non checké ici (check_content_existence le fait)
        assert tfcc.check_fields()
        assert tfcc.report.empty?
        eo.contenu = nil

        eo.validite = -1
        assert !tfcc.check_fields()
        assert !tfcc.report.empty?
        tfcc.report.erase()
        eo.validite = nil

        eo.status = "WRONG"
        assert !tfcc.check_fields()
        assert !tfcc.report.empty?
        tfcc.report.erase()
        eo.status = "actuel"
        
    end

    test 'check_content_existence' do

        eo1 = default_ensemble("s1")
        eo2 = default_ensemble("s2")
        eo3 = default_ensemble("s3")

        eo1.contenu = "s2 1 true, s3 1-2 false"

        n1 = Node.new(eo1)
        n2 = Node.new(eo2)
        n3 = Node.new(eo3)

        tfcc = TreeFieldConstraintsChecker.new(n1, n1)
        assert !tfcc.check_content_existence()
        assert !tfcc.report.empty?
        tfcc.report.erase()

        n1.add_child(n3)
        assert !tfcc.check_content_existence()
        assert !tfcc.report.empty?
        tfcc.report.erase()

        n1.add_child(n2)
        assert tfcc.check_content_existence()
        assert tfcc.report.empty?

    end

    test 'check_content_duplications' do

        eo1 = default_ensemble("s1")
        eo2 = default_ensemble("")
        eo3 = default_ensemble("s4")

        eo2.set_sigles_array(["s2","s3"])
        n1 = Node.new(eo1)
        n2 = Node.new(eo2)
        n3 = Node.new(eo3)

        eo1.contenu = "s2 1 true, s4 1-2 false"
        n1.add_child(n2)
        n1.add_child(n3)

        tfcc = TreeFieldConstraintsChecker.new(n1, n1)
        assert tfcc.check_content_duplications()
        assert tfcc.report.empty?

        eo1.contenu = "s2 1 true, s2 1-2 false"
        assert !tfcc.check_content_duplications()
        assert !tfcc.report.empty?
        tfcc.report.erase()

        eo1.contenu = "s3 1 true, s2 1-2 false"
        assert !tfcc.check_content_duplications()
        assert !tfcc.report.empty?
        tfcc.report.erase()

        eo1.contenu = "s2 1 true, s3 1-2 false"
        assert !tfcc.check_content_duplications()
        assert !tfcc.report.empty?
        tfcc.report.erase()
        
    end

    test "check_all" do

        eo = default_ensemble("s")
        n = Node.new(eo)
        tfcc = TreeFieldConstraintsChecker.new(n, n)
        assert tfcc.check_all()
        assert tfcc.report.empty?

    end

end