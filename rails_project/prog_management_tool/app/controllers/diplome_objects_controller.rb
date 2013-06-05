# encoding: utf-8

class DiplomeObjectsController < ApplicationController

    def index
        @diplomes = Diplome.all
        @title = "Liste des diplomes"
    end

    def show
        @diplome = DiplomeObject.new()
        @diplome.load(params[:id])
        @title = @diplome.sigle
    end

    def new
        @diplome = DiplomeObject.new()
        @title = "Création de diplome"
    end

    def create
        @diplome = DiplomeObject.new(params[:diplome_object])
        if(@diplome.save > 0)
            flash[:success] = "Diplome créé"
            redirect_to @diplome
        else
            @report = @diplome.report
            flash[:error] = "Impossible de créer ce diplome"
            render 'new'  
        end
    end

    def edit
        @diplome = DiplomeObject.new()
        @diplome.load(params[:id])
        @titre = "Édition de diplome"
    end

    def update

        @diplome = DiplomeObject.new()
        @diplome.load(params[:id])

        if(@diplome.update(params[:diplome_object]))
            flash[:success] = "Diplome mis à jour"
            redirect_to @diplome
        else
            @report = @diplome.report
            flash[:error] = "Impossible de mettre à jour ce diplome"
            render 'edit'
        end

    end

    def destroy
        @diplome = DiplomeObject.new()
        @diplome.load(params[:id])
        if(@diplome.destroy)
            flash[:success] = "Diplome supprimé"
            redirect_to diplome_objects_path
        else
            flash[:error] = "Impossible de supprimer ce diplome"
            render @diplome
        end
    end
  
end