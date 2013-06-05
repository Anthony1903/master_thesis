# encoding: utf-8

require 'test_helper'

class DiplomeObjectTest < ActiveSupport::TestCase

    def compaire(d1, d2)

        assert d1.cycle == d2.cycle
        assert d1.sigle == d2.sigle
        assert d1.facSigle == d2.facSigle
        assert d1.root_sigle == d2.root_sigle

    end

    test "create/load diplome" do

        eo = default_ensemble("eo")
        eid = eo.save()

        params = {}
        params[:cycle] = "master"
        params[:sigle] = "SIGLE"
        params[:facSigle] = "FACSIGLE"
        params[:root_sigle] = "eo"

        d = DiplomeObject.new(params)
        assert !d.persisted?
        id = d.save
        assert id > 0
        assert d.persisted?

        d2 = DiplomeObject.new()
        assert !d2.persisted?
        assert d2.load(id)
        assert d2.persisted?

        assert d2.cycle == "master"
        assert d2.sigle == "SIGLE"
        assert d2.facSigle == "FACSIGLE"
        assert d2.root_sigle == "eo"

        compaire(d, d2)

    end

    test "update_params" do

        params = {}
        params[:cycle] = "master"
        params[:sigle] = "SIGLE"
        params[:facSigle] = "FACSIGLE"
        params[:root_sigle] = "eo"

        d = DiplomeObject.new(params)

        assert d.cycle == "master"
        assert d.sigle == "SIGLE"
        assert d.facSigle == "FACSIGLE"
        assert d.root_sigle == "eo"

        params = {}
        params[:cycle] = "master2"
        params[:sigle] = "SIGLE2"
        params[:facSigle] = "FACSIGLE2"
        params[:root_sigle] = "eo2"

        d.update_params(params)

        assert d.cycle == "master2"
        assert d.sigle == "SIGLE2"
        assert d.facSigle == "FACSIGLE2"
        assert d.root_sigle == "eo2"

    end

    test "update diplome" do

        eo = default_ensemble("eo")
        eo2 = default_ensemble("eo2")
        eid = eo.save()
        eid2 = eo2.save()

        params = {}
        params[:cycle] = "master"
        params[:sigle] = "SIGLE"
        params[:facSigle] = "FACSIGLE"
        params[:root_sigle] = "eo"

        d = DiplomeObject.new(params)
        id = d.save
        assert id > 0

        d2 = DiplomeObject.new()
        assert d2.load(id)

        assert d2.cycle == "master"
        assert d2.sigle == "SIGLE"
        assert d2.facSigle == "FACSIGLE"
        assert d2.root_sigle == "eo"

        params = {}
        params[:cycle] = "bac"
        params[:sigle] = "SIGLE2"
        params[:facSigle] = "FACSIGLE2"
        params[:root_sigle] = "eo2"

        assert d.update(params)

        d3 = DiplomeObject.new()
        assert d3.load(id)

        assert d3.cycle == "bac"
        assert d3.sigle == "SIGLE2"
        assert d3.facSigle == "FACSIGLE2"
        assert d3.root_sigle == "eo2"

    end

    test "destroy" do

        eo = default_ensemble("eo")
        eid = eo.save()

        params = {}
        params[:cycle] = "master"
        params[:sigle] = "SIGLE"
        params[:facSigle] = "FACSIGLE"
        params[:root_sigle] = "eo"

        size = Diplome.all.size

        d = DiplomeObject.new(params)

        assert !d.persisted?

        id = d.save
        assert id > 0

        assert d.persisted?

        assert d.destroy
        assert Diplome.all.size == size

        assert !d.persisted?

    end

    def try_saving(cycle, sigle, facSigle, root_sigle, result)

        params = {}
        params[:cycle] = cycle
        params[:sigle] = sigle
        params[:facSigle] = facSigle
        params[:root_sigle] = root_sigle

        d = DiplomeObject.new(params)
        id = d.save
        assert ((id > 0) == result)

    end

    test "diplome duplications" do

        eo = default_ensemble("eo")
        eid = eo.save()

        try_saving("master", "sigle", "facSigle", "eo", true)

        try_saving("master", "sigle", "facSigle", "eo", false)  # false car idem que ligne précédente
        try_saving("bac", "sigle", "facSigle", "eo", false)     # false car même sigle que ligne précédente

        try_saving("bac", nil, "facSigle", "eo", false)   

        try_saving("bac", "sigle2", "facSigle", "eo", true)
        try_saving("master60", "sigle3", "facSigle", "eo", true)
        try_saving("passerelle", "sigle4", "facSigle", "eo", true)

        try_saving("wrong", "sigle5", "facSigle", "eo", false)
        try_saving(nil, "sigle6", "facSigle", "eo", false)

        try_saving("master", "sigle7", "facSigle", "eo2", false)
        try_saving("master", "sigle8", "facSigle", nil, false)

    end

    test "load_all" do

        eo = default_ensemble("eo")
        eo.save()

        eo2 = default_ensemble("eo2")
        eo2.save()

        params = {}
        params[:cycle] = "bac"
        params[:sigle] = "s"
        params[:facSigle] = "EPL"
        params[:root_sigle] = "eo"

        d = DiplomeObject.new(params)
        assert d.save > 0

        params[:sigle] = "s2"
        params[:root_sigle] = "eo2"

        d = DiplomeObject.new(params)
        assert d.save > 0

        list = DiplomeObject.load_all()
        assert list.size == 2
        assert list[0].sigle == "s" || list[0].sigle == "s2"
        assert list[1].sigle == "s" || list[1].sigle == "s2"
        assert list[0].sigle != list[1].sigle

    end

    test "root" do

        params = {}
        params[:cycle] = "bac"
        params[:sigle] = "s"
        params[:facSigle] = "EPL"
        params[:root_sigle] = "eo"

        # Racine inexistante

        d = DiplomeObject.new(params)
        assert d.save <= 0
        assert !d.report.empty?

        # La racin est un cours
        co = default_cours("co")
        co.save
        d = DiplomeObject.new(params)
        assert d.save <= 0
        assert !d.report.empty?
        co.destroy

        # La racine est correcte, un ensemble existant

        eo = default_ensemble("eo")
        eo.save
        d = DiplomeObject.new(params)
        assert d.save > 0
        assert d.report.empty?

    end
   
end