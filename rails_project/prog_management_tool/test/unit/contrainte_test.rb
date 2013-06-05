require 'test_helper'

class ContrainteTest < ActiveSupport::TestCase

    test "contrainte db" do

        c = Contrainte.count()

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "cours"
            )
        pm = Pmodule.last

        Sigle.create(
            :sigle => "s",
            :pmodule_id => pm.id
            )

        Sigle.create(
            :sigle => "s2",
            :pmodule_id => pm.id
            )

        Contrainte.create(
            :pmodule_id => pm.id,
            :cond => "s",
            :effet => "I"
            )

        assert Contrainte.count()==c+1

        co = Contrainte.last
        assert co.pmodule_id == pm.id
        assert co.cond == "s"
        assert co.effet == "I"

        co.update_attributes(
            :cond => "s2",
            :effet => "O"
            )

        assert Contrainte.count()==c+1

        co = Contrainte.last
        assert co.pmodule_id == pm.id
        assert co.cond == "s2"
        assert co.effet == "O"

        Contrainte.delete(co)

        assert Contrainte.count()==c

    end

    test "contrainte model" do

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "cours"
            )
        pm = Pmodule.last

        Sigle.create(
            :sigle => "s",
            :pmodule_id => pm.id
            )

        Contrainte.create(
            :pmodule_id => pm.id,
            :cond => "s",
            :effet => "I"
            )
        constr = Contrainte.last

        assert constr.pmodule == pm
        assert pm.contrainte.find_by_pmodule_id(pm.id) == constr

    end

    def check_create_for(pmodule_id, cond, effet, validity)

        begin
            Contrainte.create!(
                :pmodule_id => pmodule_id,
                :cond => cond,
                :effet => effet
                )
        rescue
            assert !validity
        else
            assert validity
        end

    end

    test "contrainte uniqueness of attr set" do 

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "cours"
            )
        pm = Pmodule.last

        Sigle.create(
            :sigle => "s1",
            :pmodule_id => pm.id
            )

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "cours"
            )
        pm2 = Pmodule.last

        Sigle.create(
            :sigle => "s2",
            :pmodule_id => pm2.id
            )

        check_create_for(pm.id, "s1", "s1", true)
        check_create_for(pm.id, "s1", "s1", false)
        check_create_for(pm2.id, "s1", "s1", true)
        check_create_for(pm.id, "s1", "s2", true)
        check_create_for(pm.id, "s2", "s1", true)

    end

end
