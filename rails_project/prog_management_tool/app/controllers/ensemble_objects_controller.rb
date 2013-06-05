# encoding: utf-8

class EnsembleObjectsController < ApplicationController

=begin

  Joue le rôle de l'index classique.
  De plus, si les paramètres sont présents, opère une sélection parmi les EnsembleObject listés.

  Paramètres éventuels : 
    "critere" : critère sur lequel la valeur sera prise en compte (un nom de colonne dans la DB)
    "valeur" : valeur telle que, si elle est présente dans la colonne "critère", cela implique l'ajout 
               dans la liste des EnsembleObject, sinon, l'EnsembleObject est ignoré.
    "status" : idem que valeur mais sous entendue pour le critère "status"

=end
    def index

        conditions = "mtype='ensemble'"

        if(params[:critere]!=nil && params[:critere].gsub(" ","")!="" && 
            params[:valeur]!=nil && params[:valeur].gsub(" ","")!="" )
            conditions += " and " + params[:critere].to_s + " LIKE '%" + params[:valeur].to_s + "%'"
        end

        if(params[:status] != nil)
            conditions += " and status='" + params[:status].to_s + "'"
        end

        # Etablis la pagination selon le contenu répondant aux critères
        @ensemble_objects =  Pmodule.joins('LEFT OUTER JOIN sigles ON pmodules.id = 
            sigles.pmodule_id').paginate(:conditions => conditions, :page => params[:page], :per_page => 25)
        @title = "Liste de tous les ensembles"

        @valeur = params[:valeur]
        @critere = params[:critere]
        @status = params[:status]

    end

    def show
        @ensemble_object = EnsembleObject.new
        @ensemble_object.load(params[:id])

        # Etablis une liste des versions liées a l'EnsembleObject concerné par le show
        @related_versions_list = []
        Sigle.all.each do |sigle| 
            @ensemble_object.sigles_array.each do |es|
                sub_es = es.split("_(")[0]
                if(sigle.sigle.split("_(")[0] == sub_es && sigle.sigle!=es) 
                    @related_versions_list << sigle.sigle
                end
            end
        end 

        @title = @ensemble_object.sigles_array[0]
    end

    def new
        @ensemble_object = EnsembleObject.new
        @title = "Création d'ensemble"
    end

    def create
        @ensemble_object = EnsembleObject.new(params[:ensemble_object])
        @report = Report.new()

        params_2 = @ensemble_object.extract_params()
        params_2[:mtype] = "ensemble"
        PmoduleObject.adapt_types(params_2)

        if(VersionManager.save(params_2, @report))
            flash[:success] = "Ensemble correctement ajouté"
            tmp = VersionManager.params_according_to_validity(params_2)
            mod = VersionManager.create_module(tmp)
            redirect_to ensemble_object_path(PmoduleObject.id?(mod.sigles_array[0]))
        else
            flash[:error] = "Impossible de créer cet ensemble"
            render 'new'
        end
    end

    def edit
        @ensemble_object = EnsembleObject.new
        @ensemble_object.load(params[:id])
        @title = "Édition d'ensemble"
    end

    def update
        @ensemble_object = EnsembleObject.new
        @report = Report.new()

        params_2 = params[:ensemble_object]
        params_2[:mtype] = "ensemble"
        PmoduleObject.adapt_types(params_2)
        @ensemble_object.update_params(params_2)

        if(VersionManager.update(params[:id], params_2, @report))
            flash[:success] = "Ensemble mis à jour"
            redirect_to ensemble_object_path(params[:id])
        else
            flash[:error] = "Impossible de mettre à jour cet ensemble"
            render 'edit'
        end
    end

=begin

Paramètre éventuel : 
"recursively" : mis à true si la suppression concerne l'ensemble, ainsi que 
tout son contenu récursivement.   

=end
    def destroy

        @ensemble_object = EnsembleObject.new
        @ensemble_object.load(params[:id])

        if(params[:recursively] == "true")
            report = Report.new()
            r = @ensemble_object.destroy_recursively(report)    
        else
            r = @ensemble_object.destroy()
            report = @ensemble_object.get_report()
        end

        if(r)
            flash[:success] = "Ensemble supprimé"
            redirect_to ensemble_objects_path
        else
            flash[:error] = report.list.join(", ")
            redirect_to @ensemble_object
        end

    end

=begin

Permet l'affichage sélectif de la liste de EnsembleObject présents dans la DB.
Le but de cette méthode est de faire une transition entre du contenu réel sélectionné, et sa signification
en tant que paire critère - valeur, et status.

Ex: si l'utilisateur choisi d'afficher tout les status, il choisi la valeur "tous", qui correspond en fait 
à une valeur nil, autrement seuls les EnsembleObject de status "tous" seront affiché (càd aucun)

Paramètre :
idem que ceux présents dans index

=end
    def restricted_index
        status = params[:status]
        if(status == "tous")   
            status = nil
        end
        redirect_to ensemble_objects_path(:critere => params[:critere],:valeur => params[:valeur], :status => status)   
    end

=begin

Charge deux modules récursivement sur les contenus, dans deux arbres.
Le but est de permettre la comparaison (visuelle, depuis l'interface) de deux modules.

Paramètres attendus :
"sigle" : sigle désignant la racine d'un arbre.
"sigle2" : sigle désignant la racine d'un second arbre.

=end
    def compaire

        @title = "comparaison de programmes"

        error_list = []
        if(params[:sigle] != nil && params[:sigle].gsub(" ","") != "")
            params[:sigle] = params[:sigle].gsub(" ","")
            tree = build_tree_for(params[:sigle])
            if(tree == nil)
                error_list << params[:sigle]
            else
                @tree_root = tree
            end
        end 

        if(params[:sigle2] != nil && params[:sigle2].gsub(" ","") != "")
            params[:sigle2] = params[:sigle2].gsub(" ","")
            tree = build_tree_for(params[:sigle2])
            if(tree == nil)
                error_list << params[:sigle]
            else
                @tree_root2 = tree
            end
        end

        if(!error_list.empty?)
            flash[:error] = "Impossible de charger les modules inconnus suivants : " + error_list.join(", ")
        end

    end

private

    # Charge le module de sigle "sigle", ainsi que son contenu dans un arbre,
    # renvoie la racine de l'arbre construit.
    def build_tree_for(sigle)
        id = PmoduleObject.id?(sigle)  
        if id == nil then return nil end

        if(Pmodule.find(id).mtype == "cours")
            m = CoursObject.new()
        else
            m = EnsembleObject.new()
        end
        m.load(id)

        new_node = Node.new(m)
        Tree.build_tree(new_node)
        return new_node
    end

end