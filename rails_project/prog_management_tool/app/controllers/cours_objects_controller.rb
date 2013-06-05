# encoding: utf-8

class CoursObjectsController < ApplicationController

=begin

  Joue le rôle de l'index classique.
  De plus, si les paramètres sont présents, opère une sélection parmi les CoursObjects listés.

  Paramètres éventuels : 
    "critere" : critère sur lequel la valeur sera prise en compte (un nom de colonne dans la DB)
    "valeur" : valeur telle que, si elle est présente dans la colonne "critère", cela implique l'ajout 
               dans la liste des CoursObjects, sinon, le CoursObjects est ignoré.
    "status" : idem que valeur mais sous entendue pour le critère "status"

=end
    def index

        conditions = "mtype='cours'"

        if(params[:critere]!=nil && params[:critere].gsub(" ","")!="" && 
           params[:valeur]!=nil && params[:valeur].gsub(" ","")!="" )
            conditions += " and " + params[:critere].to_s + " LIKE '%" + params[:valeur].to_s + "%'"
        end

        if(params[:status] != nil)
            conditions += " and status='" + params[:status].to_s + "'"
        end

        # Etablis la pagination selon le contenu répondant aux critères
        @cours_objects = Pmodule.joins('LEFT OUTER JOIN sigles ON pmodules.id = sigles.pmodule_id').paginate(:conditions => conditions, :page => params[:page], :per_page => 25)
        @title = "Liste de tous les cours"

        @valeur = params[:valeur]
        @critere = params[:critere]
        @status = params[:status]

    end

    def show
        @cours_object = CoursObject.new
        @cours_object.load(params[:id])

        # Etablis une liste des versions liées au CoursObject concerné par le show
        @related_versions_list = []
        Sigle.all.each do |sigle| 
            @cours_object.sigles_array.each do |es|
                sub_es = es.split("_(")[0]
                if(sigle.sigle.split("_(")[0] == sub_es && sigle.sigle!=es) 
                    @related_versions_list << sigle.sigle
                end
            end
        end 

        @title = @cours_object.sigles_array[0]

    end

    def new
        @cours_object = CoursObject.new
        @title = "Création de cours"
    end

    def create
        @cours_object = CoursObject.new(params[:cours_object])
        @report = Report.new()
        params_2 = @cours_object.extract_params()
        params_2[:mtype] = "cours"
        PmoduleObject.adapt_types(params_2)

        if(VersionManager.save(params_2, @report))
            flash[:success] = "Cours créé"
            tmp = VersionManager.params_according_to_validity(params_2)
            mod = VersionManager.create_module(tmp)
            redirect_to cours_object_path(PmoduleObject.id?(mod.sigles_array[0]))
        else
            flash[:error] = "Impossible de créer ce cours"
            render 'new'
        end
    end

    def edit
        @cours_object = CoursObject.new
        @cours_object.load(params[:id])
        @titre = "Édition de cours"
    end

    def update
        @cours_object = CoursObject.new
        @report = Report.new()

        params_2 = params[:cours_object]
        params_2[:mtype] = "cours"
        PmoduleObject.adapt_types(params_2)
        @cours_object.update_params(params_2)

        if(VersionManager.update(params[:id], params_2, @report))
            flash[:success] = "Cours mis à jour"
            redirect_to cours_object_path(params[:id])
        else
            flash[:error] = "Impossible de mettre à jour ce cours"
            render 'edit'
        end
    end

    def destroy
        @cours_object = CoursObject.new
        @cours_object.load(params[:id])
        if(@cours_object.destroy)
            flash[:success] = "Cours supprimé"
            redirect_to cours_objects_path
        else
            flash[:error] = @cours_object.get_report().list.join(" <br> ")
            redirect_to @cours_object
        end
    end

=begin

Permet l'affichage sélectif de la liste de CoursObjects présents dans la DB.
Le but de cette méthode est de faire une transition entre du contenu réel sélectionné, et sa signification
en tant que paire critère - valeur, et status.

Ex: si l'utilisateur choisi d'afficher tout les status, il choisi la valeur "tous", qui correspond en fait 
  à une valeur nil, autrement seuls les CoursObjets de status "tous" seront affiché (càd aucun)

Paramètres :
idem que ceux présents dans index

=end
    def restricted_index
        status = params[:status]
        if(status == "tous")
            status = nil
        end
        redirect_to cours_objects_path(:critere => params[:critere],:valeur => params[:valeur], :status => status)   
    end

end