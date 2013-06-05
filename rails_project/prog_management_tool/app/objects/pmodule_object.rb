# encoding: utf-8

require 'graph'
require 'date'

class PmoduleObject
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        # extend, include & persisted? : requis pour pouvoir lier controller et view par "form_for"

    attr_accessor :creditsMin, :creditsMax, :intitule, :langue, :dptCharge, :commentaire, :sigles, :mtype, :id, :validite, :import_commentaire, :status, :inDB

=begin  
    
    Les sigles d'un module peuvent prendre différentes formes. Dans le présentateur, ils sont 
    conservés sous forme de string ou chaque sigle est séparé par une virgule.
    Ex : "sigle1, sigle2, sigle3"
    Ce format facilite la présentation de l'objet par le contrôleur.

    Les sigles peuvent néanmoins être manipulés, via les méthodes sigles_array et 
    set_sigles_array, via un tableau. Le tableau contient un sigle par position.    
    Ex : ["sigle1", "sigle2", "sigle3"]

=end

    def initialize(param = nil)

        if(param == nil) then param = {} end
        add_default(param)

        @creditsMin = param[:creditsMin]
        @creditsMax = param[:creditsMax]
        @intitule = param[:intitule]
        @langue = param[:langue]
        @sigles = array_to_string(param[:sigles])       
        @mtype = param[:mtype]
        @dptCharge = param[:dptCharge]
        @commentaire = param[:commentaire]
        @validite = param[:validite]
        @import_commentaire = param[:import_commentaire]
        @status = param[:status]
        @report = Report.new()
        @id = nil
        @inDB = false

    end

    # Renvoie true si l'objet est présent dans la base de donnée
    def persisted?
        return @inDB
    end

    # Ajout de valeurs par défaut au paramètres passés en argument
    def add_default(params)
        if(params[:langue]==nil) 
            params[:langue] = "fr-angl"
        end
        if(params[:status]==nil) 
            params[:status] = "actuel"
        end
    end

    # Renvoie un dictionnaire contenant la valeur de chaque variable d'instance
    def extract_params_pm()
        params = {
            :creditsMax => @creditsMax,
            :creditsMin => @creditsMin,
            :intitule => @intitule,
            :langue => @langue,
            :sigles => sigles_array(),
            :mtype => @mtype,
            :dptCharge => @dptCharge,
            :commentaire => @commentaire,
            :validite => @validite,
            :import_commentaire => @import_commentaire,
            :status => @status
        }
        return params
    end

    # Modification des variables d'instances
    def update_params_pm(params)
        
        if(params[:creditsMin] != nil)
            @creditsMin = params[:creditsMin]
        end

        if(params[:creditsMax] != nil)
            @creditsMax = params[:creditsMax]
        end

        if(params[:intitule] != nil)
            @intitule = params[:intitule]
        end

        if(params[:langue] != nil)
            @langue = params[:langue]
        end

        if(params[:sigles] != nil)
            @sigles = array_to_string(params[:sigles])      
        end

        if(params[:dptCharge] != nil)
            @dptCharge = params[:dptCharge]
        end

        if(params[:commentaire] != nil)
            @commentaire = params[:commentaire]
        end

        if(params[:validite] != nil)
            @validite = params[:validite]
        end

        if(params[:import_commentaire] != nil)
            @import_commentaire = params[:import_commentaire]
        end

        if(params[:status] != nil)
            @status = params[:status]
        end
    end

    # Chargement du module désignée par "id" dans le présentateur
    def load_pm(id)
        
        @id = id

        pm = Pmodule.find_by_id(id)
        if(pm==nil) then return nil end

        @creditsMax = pm.creditsMax
        @creditsMin = pm.creditsMin
        @intitule = pm.intitule
        @langue = pm.langue
        @mtype = pm.mtype
        @dptCharge = pm.dptCharge
        @commentaire = pm.commentaire
        @validite = pm.validite
        @import_commentaire = pm.import_commentaire
        @status =  pm.status

        tmp  = []
        pm.sigle.each do |s|
           tmp << s.sigle
        end
        @sigles = array_to_string(tmp)      

        @inDB = true
            
        return pm

    end

=begin

    Sauvegarde du module dans le modèle, renvoie l'id du nouveau pmodule créé
    ou -1 si la sauvegarde a échoué.
    
    L'action échoue si les contraintes sur les pmodules ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def save_pm()
        
        pm = Pmodule.new(
            :creditsMax => @creditsMax,
            :creditsMin => @creditsMin,
            :intitule => @intitule,
            :langue => @langue,
            :mtype => @mtype,
            :dptCharge => @dptCharge,
            :commentaire => @commentaire,
            :validite => @validite,
            :import_commentaire => @import_commentaire,
            :status => @status
            )
        @errors = pm.errors
        pm.save!

        arr_sigles = string_to_array(@sigles)       

        if(arr_sigles.size == 0)
            s = pm.sigle.new(:sigle => nil)
            @errors = s.errors
            s.save!
        else
            arr_sigles.each do |s|
                s = pm.sigle.new(:sigle => s)
                @errors = s.errors
                s.save!
            end
        end

        @inDB=true

        return pm
    end


=begin
    
    Met à jour le module dans le modèle depuis les paramètres donnés.
    
    Nécessite que @id contienne l'id du module à modifier.
    
    Renvoie true si la mise à jour à réussi, false sinon.
    
    Si la mise à jour a réussi les variables d'instances sont adaptées
    sinon elles restent inchangées.
        
    L'action échoue si les contraintes sur les ensembles ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def update_pm(param)

        if(@id == nil) then return nil end
        pm = Pmodule.find(@id)
        if(pm==nil) then return nil end

        add_default(param)
        @creditsMin = param[:creditsMin]
        @creditsMax = param[:creditsMax]
        @intitule = param[:intitule]
        @langue = param[:langue]
        @sigles = array_to_string(param[:sigles])   
        @dptCharge = param[:dptCharge]
        @commentaire = param[:commentaire]
        @validite = param[:validite]
        @import_commentaire = param[:import_commentaire]
        @status = param[:status]

        @errors = pm.errors
        pm.update_attributes!(
                :creditsMax => param[:creditsMax],
                :creditsMin => param[:creditsMin],
                :intitule => param[:intitule],
                :langue => param[:langue],
                :dptCharge => param[:dptCharge],
                :commentaire => param[:commentaire],
                :validite => param[:validite],
                :import_commentaire => param[:import_commentaire],
                :status => param[:status]
                )

        pm.sigle.each do |s|
            @errors = s.errors
            s.destroy
        end

        arr_sigles = string_to_array(param[:sigles])        
        arr_sigles.each do |s|
            s = pm.sigle.new(:sigle => s)
            @errors = s.errors
            s.save!
        end

        return pm
    end

    # Supprime le module du modèle (destruction en cascade due aux
    # informations données dans le modèle, vois models/pmodule.rb).
    # Nécessite que @id contienne l'id du module à supprimer.
    # Renvoie false si les contraintes interdisent cette suppression,
    # et que force est à false, true sinon
    def destroy(force = false)
        if @id == nil then return false end
        if !force && !can_remove?() then return false end
        pm = Pmodule.find(@id)

        pm.destroy # Voir model Pmodule pour la destruction des relations
        @inDB = false
        return true
    end

    # Supprime le module du modèle via destroy, ainsi que tout les 
    # modules contenus par celui-ci si le module est un ensemble.
    # Renvoie false si les contraintes interdisent cette suppression, 
    # true sinon
    def destroy_recursively(report)

        # Constuit la liste des exceptions, correspondant à tous 
        # les sigles des modules contenu par celui-ci, si il en existe.
        # Construit parallèlement la liste des modules contenus récursivement

        exceptions = recursive_content_sigles()
        mod_list = []
        mod_list << self

        ids = [@id]

        while(ids.empty? == false)
            i = ids.pop
            EnsembleContenu.find_all_by_pmodule_id(i).each do |c|
                if(Pmodule.find(c.contenu_id).mtype == "cours")
                    mod = CoursObject.new
                else
                    mod = EnsembleObject.new
                end
                mod.load(c.contenu_id)
                mod_list << mod
                ids << c.contenu_id
            end
        end
        
        # Supprime tout si permis
        if(!can_destroy_recursively?(report, exceptions))
            return false
        else
            mod_list.each do |m|
                # Supprime si il existe encore (possible qu'il ait été supprimé avant
                # car le contenu peut reprendre deux fois le même module
                if(PmoduleObject.id?(m.sigles_array[0]) != nil)
                    m.destroy(true)
                end
            end
        end

        return true
    end

    # Renvoie true si le module peut-être supprimé selon can_remove,
    # et si il en va de même pour chaque élément contenu si le module 
    # est un ensemble, récursivement. La liste d'exception contient 
    # l'ensemble des sigles des module qui doivent être ignorés par can_remove
    def can_destroy_recursively?(report, exceptions = nil)
        if exceptions == nil then exceptions = recursive_content_sigles() end
        if(!can_remove?(exceptions) || !@inDB)
            report.merge(@report)
            return false
        elsif(mtype == "ensemble")
            EnsembleContenu.find_all_by_pmodule_id(@id).each do |ec|
                po = PmoduleObject.new()
                po.load_pm(ec.contenu_id) 
                if(!po.can_destroy_recursively?(report, exceptions))
                    return false
                end
            end
        end
        return true
    end

    # Renvoie le rapport après y avoir ajouté les messages d'erreurs
    # contenus par @errors (erreurs données par le framework lors de save
    # ou update)
    def get_report()
        if(@errors!=nil)
            @errors.full_messages.each do |m|
                @report.write(m,"Errors")
            end
        end
        report = Report.new
        report.merge(@report)
        return report
    end

    # Vide le rapport
    def erase_report()
        @report.erase()
    end

    # Crée une image représentant la structure formée par ce module,
    # ses éventuel éléments contenu, et ses éventuels ancêtres, en utilisant "Graph"
    # La structure se construit récursivement sur le contenu et les ancêtres.
    def build_complete_graph(time_stamp = nil)
        begin
            vertices = []
            edges = []

            vertices << sigles_array[0]

            ids = [@id]

            # Ajoute les paires <sigle1, sigle2> telle que le tout forme une chaine
            # allant de la racine au module
            while(ids.empty? == false)
                i = ids.pop
                EnsembleContenu.find_all_by_contenu_id(i).each do |c|
                    s = Sigle.find_by_pmodule_id(c.pmodule_id).sigle
                    s2 = Sigle.find_by_pmodule_id(c.contenu_id).sigle
                    vertices << s
                    edges << [s, s2]
                    ids << c.pmodule_id
                end
            end

            ids = [@id]

            # Ajoute les paires <sigle1, sigle2> telle que le tout forme un arbre
            # allant du module vers toutes les feuilles.
            while(ids.empty? == false)
                i = ids.pop
                EnsembleContenu.find_all_by_pmodule_id(i).each do |c|
                    s = Sigle.find_by_pmodule_id(c.pmodule_id).sigle
                    s2 = Sigle.find_by_pmodule_id(c.contenu_id).sigle
                    vertices << s
                    edges << [s, s2]
                    ids << c.contenu_id
                end
            end

            # Crée l'image
            g = Graph.new("c_graph#{@id}#{time_stamp}", vertices, edges)
            g.save

        rescue
            return false
        end
        return true
    end

    # Crée une image représentant la structure formée par ce module,
    # ses éventuel éléments contenu, et ses éventuels ancêtres, en utilisant "Graph".
    def build_graph()
        begin
            vertices = []
            edges = []

            vertices << sigles_array[0]

            # Ajoute des paires <parent_sigle, module_sigle> pour chaque parent du
            # contenant le module.
            EnsembleContenu.find_all_by_contenu_id(@id).each do |c|
                s = Sigle.find_by_pmodule_id(c.pmodule_id).sigle
                s2 = Sigle.find_by_pmodule_id(c.contenu_id).sigle
                vertices << s
                edges << [s, s2]
            end

            # Ajoute des paires <module_sigle, contenu_sigle> pour chaque module 
            # contenu par le module si celui-ci est un ensemble.
            EnsembleContenu.find_all_by_pmodule_id(@id).each do |c|
                s = Sigle.find_by_pmodule_id(c.pmodule_id).sigle
                s2 = Sigle.find_by_pmodule_id(c.contenu_id).sigle
                vertices << s2
                edges << [s, s2]
            end

            g = Graph.new("graph"+@id.to_s, vertices, edges)
            g.save

        rescue
            return false
        end
        return true
    end

    # Renvoie les sigles du module sous forme de tableau
    def sigles_array()
        return string_to_array(@sigles)
    end

    # Modifie les sigles du module depuis une version tableau des sigles
    def set_sigles_array(sigles)
        @sigles = array_to_string(sigles)
    end

    # Vérifie les contraintes légales sur le module
    def check_legal_constraints()
        dlcc = DbLegalConstraintsChecker.new(self)

        if(!dlcc.check_all())
            @report.merge(dlcc.report)
            return false
        end 
        return true
    end

    # Vérifie les contraintes autres que légales
    def check_constraints(mod)
        dscc = DbStructuralConstraintsChecker.new(mod)
        flcc = DbFieldConstraintsChecker.new(mod)

        # Ne pas checker les fields sinon boucle infinie (car utilise le présentateur)
        # Ne pas checker les parents (doit être demandé excplicitement)
        # Raison : permet de modifier des programmes en les sauvant des feuilles vers la racine
        #          Si les parents sont vérifiés : impossible de modifier un programme existant
        if((!flcc.check_content_existence() | !flcc.check_content_duplications()) || !dscc.check_all_except_parent())
            @report.merge(dscc.report)
            @report.merge(flcc.report)
            return false
        end 

        return true
    end

    # Adapte le type des paramètres en fonction de ce qui est attendu par un module
    def self.adapt_types(params)
        if params == nil then return end
        if(params["creditsMax"].to_s.gsub(" ","") != "")
            params["creditsMax"] = params["creditsMax"].to_i
        end
        if(params["creditsMin"].to_s.gsub(" ","") != "")
            params["creditsMin"] = params["creditsMin"].to_i
        end
        if(params["validite"].to_s.gsub(" ","") != "")
            params["validite"] = params["validite"].to_i
        end
        CoursObject.adapt_types(params)
    end

    # Renvoie l'id du pmodule associé au sigle, ou nil si il n'y en a aucun.
    def PmoduleObject.id?(sigle)
        if(sigle != nil) then sigle = sigle.gsub(" ","") end
        s = Sigle.find_by_sigle(sigle)
        if(s==nil)
            return nil
        else
            return s.pmodule_id
        end
    end

private

    # Converti un string en format tableau se basant sur les virgules
    def string_to_array(string)
        if string.kind_of?(String)
            return string.gsub(" ","").split(",")
        else
            return string
        end
    end

    # Converti un tableau en format string utilisant les virgules comme séparateurs
    def array_to_string(array)
        if array.kind_of?(Array)
            return array.join(", ")
        else
            return array
        end
    end

    # Renvoie un dictionnaire contenant la valeur actuelles des variables d'instance 
    def var_backup()
        backup = {}
        backup[:creditsMin] = @creditsMin
        backup[:creditsMax] = @creditsMax
        backup[:intitule] = @intitule
        backup[:langue] = @langue
        backup[:mtype] = @mtype
        backup[:sigles] = @sigles
        backup[:dptCharge] = @dptCharge
        backup[:commentaire] = @commentaire
        backup[:validite] = @validite
        backup[:import_commentaire] = @import_commentaire
        backup[:status] = @status
        return backup
    end

    # Modifie les variables d'instance en fonction du dictionnaire "backup"
    def var_restore(backup)
        @creditsMin = backup[:creditsMin] 
        @creditsMax = backup[:creditsMax]
        @intitule = backup[:intitule]
        @langue = backup[:langue]
        @mtype = backup[:mtype]
        @sigles = backup[:sigles]
        @dptCharge = backup[:dptCharge] 
        @commentaire = backup[:commentaire]
        @validite = backup[:validite]
        @import_commentaire = backup[:import_commentaire] 
        @status = backup[:status]
    end

    # Renvoie true si le module n'est référencé dans aucun contenu 
    # d'ensemble, ou si les ensembles le contenant possèdent un des
    # sigles listés dans "exceptions", et n'est mentionné dans aucune
    # contrainte. Renvoie false sinon.
    def can_remove?(exceptions = [])

        result = true

        # Vérifications concernant les contenus
        EnsembleContenu.all.each do |c|
            if(c.contenu_id.to_i == @id.to_i && !module_in_sigle_list?(exceptions, c.pmodule_id))
                @report.write("Les modules étant encore contenu par un ou plusieurs ensembles ne peuvent être supprimés (cas de " + sigles_array()[0].to_s + ")","Remove pmodule")
                result = false
            end
        end

        # Vérifications concernant les contraintes
        ContrainteObject.load_all().each do |co|
            ccc = ChoiceConstraintsChecker.new(co)
            constr_sigles = ccc.extract_sigles
            sigles_array().each do |s|
                if(constr_sigles.index(s)!=nil)
                    @report.write("Les modules dont le sigle est encore utilisé dans au moins une contrainte ne peuvent être supprimés (cas de " + s.to_s + ")","Remove pmodule")
                    result = false
                end
            end
        end

        return result
    
    end

    # Renvoie true si le module associé à "id" possède un sigle
    # étant présent dans la liste "list", false sinon.  
    def module_in_sigle_list?(list, id)
        po = PmoduleObject.new()
        po.load_pm(id)

        arr = po.sigles_array()
        list.each do |e|
            if(arr.index(e)!=nil)
                return true
            end
        end

        return false
    end

    # Renvoie la liste de tous les sigles des modules contenu par celui-ci
    # si il en existe, ainsi que le sigle du module lui_même.
    def recursive_content_sigles()

        exceptions = []
        exceptions << sigles_array[0]

        ids = [@id]

        while(ids.empty? == false)
            i = ids.pop
            EnsembleContenu.find_all_by_pmodule_id(i).each do |c|
                if(Pmodule.find(c.contenu_id).mtype == "cours")
                    mod = CoursObject.new()
                else
                    mod = EnsembleObject.new()
                end
                mod.load(c.contenu_id)
                exceptions << mod.sigles_array[0]
                ids << c.contenu_id
            end
        end

        return exceptions

    end

end
