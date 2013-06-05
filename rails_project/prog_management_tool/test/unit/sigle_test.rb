require 'test_helper'

class SigleTest < ActiveSupport::TestCase

    test "sigle db" do

        c = Sigle.count()

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype   => "cours"
            )
        pm1 = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype   => "cours"
            )
        pm2 = Pmodule.last

        Sigle.create(
            :pmodule_id => pm1.id,
            :sigle => "sigle"
            )
        s = Sigle.last

        assert Sigle.count()==c+1

        assert s.pmodule_id == pm1.id
        assert s.sigle == "sigle"

        s.update_attributes(
            :pmodule_id => pm2.id,
            :sigle => "sigle2"
            )

        assert Sigle.count()==c+1

        s = Sigle.last
        assert s.pmodule_id == pm2.id
        assert s.sigle == "sigle2"

        Sigle.delete(s)

        assert Sigle.count()==c

    end

    def check_create_for(pmodule_id, sigle, validity)

        begin
            Sigle.create!(
                :pmodule_id => pmodule_id,
                :sigle => sigle
                )
        rescue
            assert !validity
        else
            assert validity
        end

    end

    test "sigle model" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype   => "cours"
            )
        pm = Pmodule.last

        Sigle.create(
            :pmodule_id => pm.id,
            :sigle => "sigle"
            )
        s = Sigle.last

        assert s.pmodule == pm
        assert pm.sigle.find_by_sigle("sigle") == s

    end

    test "sigle foreign key" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype   => "cours"
            )
        pm = Pmodule.last

        check_create_for(pm.id+1, "sigle", false)
        check_create_for(pm.id, "sigle", true)

        end

        test "sigle uniqueness of attr set" do 

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype   => "cours"
            )
        pm = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype   => "cours"
            )
        pm2 = Pmodule.last

        check_create_for(pm.id, "sigle", true)
        check_create_for(pm.id, "sigle", false)
        check_create_for(pm.id, "sigle2", true)
        check_create_for(pm2.id, "sigle", false)

    end

end
