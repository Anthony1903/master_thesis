require 'test_helper'

class CoursContenuTest < ActiveSupport::TestCase

    test "cours contenu db" do

        c = CoursContenu.count()

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :mtype => "cours"
            )
        pm1 = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm2 = Pmodule.last

        CoursContenu.create(
            :dureeCours => 27.75,
            :dureeTP => 30,
            :quadri => 1,
            :professeur => "professeur",
            :pmodule_id => pm1.id
            )

        assert CoursContenu.count()==c+1

        co = CoursContenu.last
        assert co.pmodule_id == pm1.id
        assert co.dureeCours == 27.75
        assert co.dureeTP == 30
        assert co.quadri == 1
        assert co.professeur == "professeur"

        co.update_attributes(
            :dureeCours => 32,
            :dureeTP => 32.75,
            :quadri => 2,
            :professeur => "professeur2",
            :pmodule_id => pm2.id
            )

        assert CoursContenu.count()==c+1

        co = CoursContenu.last
        assert co.pmodule_id == pm2.id
        assert co.dureeCours == 32
        assert co.dureeTP == 32.75
        assert co.quadri == 2
        assert co.professeur == "professeur2"

        CoursContenu.delete(co)

        assert CoursContenu.count()==c

    end

    test "cours contenu model" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm = Pmodule.last

        CoursContenu.create(
            :dureeCours => 30,
            :dureeTP => 30,
            :quadri => 1,
            :professeur => "professeur",
            :pmodule_id => pm.id
            )
        c = CoursContenu.last

        assert pm.cours_contenu==c
        assert c.pmodule==pm

    end


    def check_create_for(dureeCours, dureeTP, quadri, professeur, pmodule_id, validity)

        begin
            CoursContenu.create!(
                :dureeCours => dureeCours,
                :dureeTP => dureeTP,
                :quadri => quadri,
                :professeur => professeur,
                :pmodule_id => pmodule_id
                )
        rescue
            assert !validity
        else
            assert validity
        end

    end

    test "cours contenu inclusion" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm1 = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm2 = Pmodule.last

        check_create_for(30, 30, "WRONG", "professeur", pm1.id, false)
        check_create_for(30, 30, 3, "professeur", pm1.id, false)
        check_create_for(30, 30, 1, "professeur", pm1.id, true)
        check_create_for(30, 30, 2, "professeur", pm2.id, true)

    end

    test "cours contenu foreign key" do 

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm = Pmodule.last

        check_create_for(30, 30, 1, "professeur", pm.id+1, false)
        check_create_for(30, 30, 1, "professeur", pm.id, true)

    end

    test "cours contenu numericality_of" do 

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm2 = Pmodule.last

        check_create_for($DUREE_MIN-1, $DUREE_MIN, 1, "professeur", pm.id, false)
        check_create_for($DUREE_MIN, $DUREE_MIN-1, 1, "professeur", pm.id, false)
        check_create_for($DUREE_MAX+1, $DUREE_MIN, 1, "professeur", pm.id, false)
        check_create_for($DUREE_MIN, $DUREE_MAX+1, 1, "professeur", pm.id, false)
        check_create_for($DUREE_MIN, $DUREE_MAX, 1, "professeur", pm.id, true)
        check_create_for($DUREE_MAX, $DUREE_MIN, 1, "professeur", pm2.id, true)

    end

    test "cours et ensemble" do

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "ensemble"
            )
        pm1 = Pmodule.last

        Pmodule.create(
            :creditsMax => 7,
            :creditsMin => 7,
            :mtype => "cours"
            )
        pm2 = Pmodule.last

        EnsembleContenu.create(
            :pmodule_id => pm1.id,
            :contenu_id => pm2.id,
            :annee => "1",
            :obligatoire => true
            )

        check_create_for($DUREE_MIN, $DUREE_MIN, 1, "professeur", pm1.id, false)
        check_create_for($DUREE_MIN, $DUREE_MIN, 1, "professeur", pm2.id, true)
        
    end

end
