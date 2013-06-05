require 'test_helper'

class DiplomeTest < ActiveSupport::TestCase
	
    def check_create_for(sigle, cycle, facSigle, pmodule_id, validity)

        begin
            Diplome.create!(
                :sigle => sigle,
                :cycle => cycle,
                :facSigle => facSigle,
                :pmodule_id => pmodule_id
                )
        rescue
            assert !validity
        else
            assert validity
        end

    end

    test "diplome db" do

        c = Diplome.count()

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype   => "ensemble"
            )
        pm1 = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype   => "ensemble"
            )
        pm2 = Pmodule.last

        Diplome.create(
            :sigle => "sigle",
            :cycle => "bac",
            :facSigle => "facSigle",
            :pmodule_id => pm1.id
            )
        d = Diplome.last

        assert Diplome.count()==c+1

        assert d.sigle == "sigle"
        assert d.cycle == "bac"
        assert d.facSigle == "facSigle"
        assert d.pmodule_id == pm1.id

        d.update_attributes(
            :cycle => "master",
            :facSigle => "facSigle2",
            :pmodule_id => pm2.id
            )

        assert Diplome.count()==c+1

        d = Diplome.last
        assert d.sigle == "sigle"
        assert d.cycle == "master"
        assert d.facSigle == "facSigle2"
        assert d.pmodule_id == pm2.id

        Diplome.delete(d)

        assert Diplome.count()==c

    end

    test "diplome model" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :intitule => "intitule",
            :langue => "fr",
            :mtype   => "ensemble"
            )
        pm = Pmodule.last

        Diplome.create(
            :sigle => "sigle",
            :cycle => "bac",
            :facSigle => "facSigle",
            :pmodule_id => pm.id
            )
        d = Diplome.last

        assert d.pmodule == pm
        assert pm.diplome.find_by_sigle("sigle") == d

    end

    test "diplome inclusion" do

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "ensemble"
            )
        pm = Pmodule.last

        check_create_for("sigle", "WRONG", "facSigle", pm.id, false)
        check_create_for("sigle", "bac", "facSigle", pm.id, true)
        check_create_for("sigle2", "master", "facSigle", pm.id, true)

    end

    test "diplome foreign key" do

        Pmodule.create(
        :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "ensemble"
            )
        pm = Pmodule.last

        check_create_for("sigle", "bac", "facSigle", pm.id+1, false)
        check_create_for("sigle", "bac", "facSigle", pm.id, true)

    end

    test "diplome root type" do

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "cours"
            )
        pm = Pmodule.last

        check_create_for("sigle", "bac", "facSigle", pm.id, false)

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "ensemble"
            )
        pm = Pmodule.last

        check_create_for("sigle", "bac", "facSigle", pm.id, true)

    end

end
