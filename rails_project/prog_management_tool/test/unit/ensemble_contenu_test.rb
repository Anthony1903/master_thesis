require 'test_helper'

class EnsembleContenuTest < ActiveSupport::TestCase

    def create_module(sigle)

        Pmodule.create(
        :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "ensemble"
            )
        pm = Pmodule.last

        if(sigle != nil)
            Sigle.create(
                :pmodule_id => pm.id,
                :sigle => sigle
                )
        end

        return pm

    end

    def check_create_for(pmodule_id, contenu_id, annee, obligatoire, validity)

        begin
            EnsembleContenu.create!(
                :pmodule_id => pmodule_id,
                :contenu_id => contenu_id,
                :annee => annee,
                :obligatoire => obligatoire
                )
        rescue 
            assert !validity
        else
            assert validity
        end

    end

    test "ensemble contenu db" do

        c = EnsembleContenu.count()

        pm1 = create_module(nil)
        pm2 = create_module(nil)
        pm3 = create_module(nil)

        EnsembleContenu.create(
            :pmodule_id => pm1.id,
            :contenu_id => pm2.id,
            :annee => "1",
            :obligatoire => true
            )

        assert EnsembleContenu.count()==c+1

        ce = EnsembleContenu.last
        assert ce.pmodule_id == pm1.id
        assert ce.contenu_id == pm2.id
        assert ce.annee == "1"
        assert ce.obligatoire == true

        ce.update_attributes(
            :contenu_id => pm3.id,
            :annee => "2",
            :obligatoire => false
            )

        assert EnsembleContenu.count()==c+1

        ce = EnsembleContenu.last
        assert ce.pmodule_id == pm1.id
        assert ce.contenu_id == pm3.id
        assert ce.annee == "2"
        assert ce.obligatoire == false

        EnsembleContenu.delete(ce)

        assert EnsembleContenu.count()==c

    end

    test "ensemble contenu model" do 

        pm1 = create_module(nil)
        pm2 = create_module(nil)

        EnsembleContenu.create(
            :pmodule_id => pm1.id,
            :contenu_id => pm2.id,
            :annee => "1",
            :obligatoire => true
            )
        c = EnsembleContenu.last

        assert c.pmodule == pm1
        assert c.contenu == pm2
        assert pm2.conteneur.find_by_contenu_id(pm2.id) == c
        assert pm1.contenu.find_by_pmodule_id(pm1.id) == c 

    end

    test "ensemble contenu inclusion" do

        pm1 = create_module(nil)
        pm2 = create_module(nil)

        check_create_for(pm1.id, pm2.id, "WRONG", false, false)
        check_create_for(pm1.id, pm2.id, "1-", false, false)
        check_create_for(pm1.id, pm2.id, "1-2", false, true)

    end

    test "ensemble contenu foreign key" do 

        pm1 = create_module(nil)
        pm2 = create_module(nil)

        check_create_for(pm1.id+2, pm2.id, "1", false, false)
        check_create_for(pm1.id, pm2.id+1, "1", false, false)
        check_create_for(pm1.id, pm2.id, "1", false, true)

    end


    test "ensemble contenu uniqueness of attr set" do 

        pm1 = create_module(nil)
        pm2 = create_module(nil)
        pm3 = create_module(nil)
        pm4 = create_module(nil)

        check_create_for(pm1.id, pm2.id, "1", false, true)
        check_create_for(pm1.id, pm2.id, "1", false, false)
        check_create_for(pm1.id, pm2.id, "2", false, false)
        check_create_for(pm3.id, pm2.id, "1", false, true)
        check_create_for(pm1.id, pm4.id, "1", false, true)

    end

    test "ensemble et cours" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm1 = Pmodule.last

        pm2 = create_module(nil)

        CoursContenu.create(
            :dureeCours => 30,
            :dureeTP => 30,
            :quadri => 1,
            :professeur => "professeur",
            :pmodule_id => pm1.id
            )

        check_create_for(pm1.id, pm2.id, "1", false, false)
        check_create_for(pm2.id, pm1.id, "1", false, true)

    end

end
