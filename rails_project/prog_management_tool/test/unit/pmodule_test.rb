require 'test_helper'

class PmoduleTest < ActiveSupport::TestCase
 
  test "pmodule db" do

        c = Pmodule.count()

        Pmodule.create(
            :creditsMax => 5,
            :creditsMin => 5,
            :intitule => "intitule",
            :langue => "fr",
            :mtype   => "cours",
            :dptCharge   => "INGI",
            :commentaire   => "commentaire",
            :validite   => 2012,
            :import_commentaire   => "import commentaire", 
            :status   => "actuel"
            )

        assert Pmodule.count()==c+1

        m = Pmodule.last
        assert m.creditsMax == 5
        assert m.creditsMin == 5
        assert m.intitule == "intitule"
        assert m.langue == "fr"
        assert m.mtype == "cours"
        assert m.dptCharge == "INGI"
        assert m.commentaire == "commentaire"
        assert m.validite == 2012
        assert m.import_commentaire == "import commentaire"
        assert m.status == "actuel"

        m.update_attributes(
            :creditsMax => 7,
            :creditsMin => 7,
            :intitule => "intitule2",
            :langue => "fr",
            :mtype   => "ensemble",
            :dptCharge   => "INGI2",
            :commentaire   => "commentaire2",
            :validite   => 2013,
            :import_commentaire   => "import commentaire2",
            :status   => "future"
            )

        assert Pmodule.count()==c+1

        m = Pmodule.last
        assert m.creditsMax == 7
        assert m.creditsMin == 7
        assert m.intitule == "intitule2"
        assert m.mtype   == "ensemble"
        assert m.langue == "fr"
        assert m.dptCharge == "INGI2"
        assert m.commentaire == "commentaire2"
        assert m.validite == 2013
        assert m.import_commentaire == "import commentaire2"
        assert m.status == "future"

        Pmodule.delete(m)

        assert Pmodule.count()==c

    end

    def check_create_for(intitule, langue, mtype, creditsMin, creditsMax, dptCharge, commentaire, validite, import_commentaire, status, validity)

        begin
            Pmodule.create!(
                :creditsMax => creditsMax,
                :creditsMin => creditsMin,
                :intitule => intitule,
                :langue => langue,
                :mtype => mtype,
                :dptCharge   => dptCharge,
                :commentaire   => commentaire,
                :validite   => validite,
                :import_commentaire   => import_commentaire,
                :status => status
                )
        rescue
            assert !validity
        else
            assert validity
        end

    end

    test "pmodule inclusion" do

        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "WRONG", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "archive", true)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "future", true)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", true)
        check_create_for("int","WRONG","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", false)
        check_create_for("int","angl","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", true)
        check_create_for("int","fr-angl","cours",$CREDITS_MIN, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", true)

    end

    test "pmodule numericality_of" do 

        check_create_for("int","fr","cours",$CREDITS_MIN-1, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MIN-1, "INGI","commentaire", 2012, "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MAX+1, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX+1, "INGI","commentaire", 2012, "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX, "INGI","commentaire", 2012, "import com", "actuel", true)
        check_create_for("int","fr","cours",$CREDITS_MAX, $CREDITS_MIN, "INGI","commentaire", 2012, "import com", "actuel", false)

        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX, "INGI","commentaire", "WRONG", "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX, "INGI","commentaire", $VALIDITE_MIN-1, "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX, "INGI","commentaire", $VALIDITE_MAX+1, "import com", "actuel", false)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX, "INGI","commentaire", $VALIDITE_MIN, "import com", "actuel", true)
        check_create_for("int","fr","cours",$CREDITS_MIN, $CREDITS_MAX, "INGI","commentaire", $VALIDITE_MAX, "import com", "actuel", true)

    end


end
