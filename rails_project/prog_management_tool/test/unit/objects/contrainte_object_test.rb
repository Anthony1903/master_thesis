require 'test_helper'

class ContrainteObjectTest < ActiveSupport::TestCase

    def compaire(c1, c2)

        assert c1.target == c2.target
        assert c1.cond == c2.cond
        assert c1.effet == c2.effet

    end

    def create_contrainte(target, cond, effet)

        param = {}
        param[:target] = target
        param[:cond] = cond
        param[:effet] = effet

        return ContrainteObject.new(param)

    end

    test "format_expr" do

        c = create_contrainte(" * ", "A&(B       &C)|(!D||(    A&    &(B)))", "E(A)&(T  (B)&C(C)  |(!D||(A&&(B)))")

        # Vérification que les expressions contiennent 1 espace entre chaque symbole
        assert c.target == "*"
        assert c.cond == "A & ( B & C ) | ( ! D || ( A && ( B ) ) )"
        assert c.effet == "E ( A ) & ( T ( B ) & C ( C ) | ( ! D || ( A && ( B ) ) )"

    end

    test "create/load contrainte" do

        eo = default_ensemble("s")
        assert eo.save

        eo2 = default_ensemble("s2")
        assert eo2.save

        c = create_contrainte("*","s","s2")
        assert !c.persisted?
        id = c.save
        assert c.persisted?
        assert id > 0

        c2 = ContrainteObject.new()
        assert !c2.persisted?
        assert c2.load(id)
        assert c2.persisted?

        assert c2.target == "*"
        assert c2.cond == "s"
        assert c2.effet == "s2"

        compaire(c, c2)

    end

    test "update_params" do 

        c = create_contrainte("*","s","s2")

        assert c.target == "*"
        assert c.cond == "s"
        assert c.effet == "s2"

        params = {}
        params[:target] = "s"
        params[:cond] = "s2"
        params[:effet] = "s3"

        c.update_params(params)

        assert c.target == "s"
        assert c.cond == "s2"
        assert c.effet == "s3"

    end

    test "update contrainte" do

        eo = default_ensemble("s")
        assert eo.save

        eo2 = default_ensemble("s2")
        assert eo2.save

        c = create_contrainte("*","s","s2")
        id = c.save
        assert id > 0

        c2 = ContrainteObject.new()
        assert c2.load(id)

        param2 = {}
        param2[:target] = "*"
        param2[:cond] = "s10"
        param2[:effet] = "s2"

        assert !c2.update(param2)

        assert c2.target == "*"
        assert c2.cond == "s"
        assert c2.effet == "s2"

        param2[:cond] = "s2"
        param2[:effet] = "s"

        assert c2.update(param2)

        c3 = ContrainteObject.new()

        assert c3.load(id)
        assert c3.target == "*"
        assert c3.cond == "s2"
        assert c3.effet == "s"

    end

    test "destroy contrainte" do

        eo = default_ensemble("s")
        assert eo.save

        eo2 = default_ensemble("s2")
        assert eo2.save

        param = {}
        param[:target] = "*"
        param[:cond] = "s"
        param[:effet] = "s2"

        c = ContrainteObject.new(param)

        Contrainte.all.length == 0

        id = c.save
        assert id > 0

        Contrainte.all.length == 1

        c2 = ContrainteObject.new()
        c2.load(id)

        assert c2.persisted?

        c2.destroy

        assert !c2.persisted?

        Contrainte.all.length == 0

    end

    test "load_all" do

        eo = default_ensemble("s")
        assert eo.save

        eo2 = default_ensemble("s2")
        assert eo2.save

        c = create_contrainte("*","s","s2")
        c2 = create_contrainte("*","s2","s")

        assert c.save > 0
        assert c2.save > 0

        list = ContrainteObject.load_all()
        assert list.size == 2
        assert list[0].cond == "s" || list[0].cond == "s2"
        assert list[1].cond == "s" || list[1].cond == "s2"
        assert list[0].cond != list[1].cond

    end

end