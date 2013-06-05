# encoding: utf-8

class ContrainteObjectsController < ApplicationController

    def index
        @title = "Liste de toutes les contraintes"
        @contrainte_objects = Contrainte.paginate(:page => params[:page], :per_page => 25)
        render 'contrainte_objects/index'
    end

    def show
    	@contrainte_object = ContrainteObject.new
        @contrainte_object.load(params[:id])
    end

    def new
        @contrainte_object = ContrainteObject.new
        @title = "Création de contrainte"
    end

    def create
        @contrainte_object = ContrainteObject.new(params[:contrainte_object])
        if @contrainte_object.save() > 0
            flash[:success] = "Contrainte correctement ajoutée"
            redirect_to @contrainte_object
        else
            flash[:error] = "Impossible de créer cette contrainte"
            render 'new'
        end
    end

    def edit
        @contrainte_object = ContrainteObject.new
        @contrainte_object.load(params[:id])
        @title = "Édition de contrainte"
    end

    def update
        @contrainte_object = ContrainteObject.new
        @contrainte_object.load(params[:id])
        @contrainte_object.update_params(params[:contrainte_object])
        if @contrainte_object.update(params[:contrainte_object])
          flash[:success] = "Contrainte mise à jour"
          redirect_to @contrainte_object
        else
          flash[:error] = "Impossible de mettre à jour cette contrainte"
          render 'edit'
        end
    end

    def destroy
        @contrainte_object = ContrainteObject.new
        @contrainte_object.load(params[:id])
        @contrainte_object.destroy
        redirect_to contrainte_objects_path
    end
  
end