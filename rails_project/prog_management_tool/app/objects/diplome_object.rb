# encoding: utf-8


class DiplomeObject
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        # extend, include & persisted? : requis pour pouvoir lier controller et view par "form_for"

    attr_accessor :cycle, :sigle, :facSigle, :root_sigle, :report, :id, :inDB

    def initialize(params = nil)
        if(params == nil) then params = {} end
        @cycle = params[:cycle]
        @sigle = params[:sigle]
        @facSigle = params[:facSigle]
        @root_sigle = params[:root_sigle]
        @inDB = false
        @report = Report.new()

        if @sigle != nil then @sigle = @sigle.gsub(" ","") end
        if @facSigle != nil then @facSigle = @facSigle.gsub(" ","") end
        if @root_sigle != nil then @root_sigle = @root_sigle.gsub(" ","") end
    end
    
    # Modification des variables d'instances
    def update_params(params)

        if(params[:cycle] != nil)
            @cycle = params[:cycle]
        end
        if(params[:sigle] != nil)
            @sigle = params[:sigle]
        end
        if(params[:facSigle] != nil)
            @facSigle = params[:facSigle]
        end
        if(params[:root_sigle] != nil)
            @root_sigle = params[:root_sigle]
        end

        if @sigle != nil then @sigle = @sigle.gsub(" ","") end
        if @facSigle != nil then @facSigle = @facSigle.gsub(" ","") end
        if @root_sigle != nil then @root_sigle = @root_sigle.gsub(" ","") end

    end

    # Renvoie true si l'objet est présent dans la base de donnée
    def persisted?
        return @inDB
    end

    # Chargement du diplome désigné par "id", dans le présentateur
    def load(id)
        
        d = Diplome.find(id)
        if(d==nil) then return false end

        @cycle = d.cycle
        @sigle = d.sigle
        @facSigle = d.facSigle
        @root_sigle = get_root_sigle(d.pmodule_id)
        @id = d.id
        @inDB = true

        return true

    end


=begin

    Sauvegarde du diplome dans le modèle, renvoie l'id du nouveau diplome créé
    ou -1 si la sauvegarde a échoué.
    
    L'action échoue si les contraintes sur les diplomes ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def save()

        id = get_root_id(@root_sigle)
        
        if(!check_fields())
            return -1
        end
        
        d = Diplome.new(
            :cycle => @cycle,
            :sigle => @sigle,
            :facSigle => @facSigle,
            :pmodule_id => id
            )

        begin
            d.save!()
            @id = d.id  
            @inDB = true
            return d.id 
        rescue
            d.errors.full_messages.each do |m|
                @report.write(m,"DiplomeObject save")
            end
            return -1
        end

    end

=begin
    
    Met à jour le diplome dans le modèle depuis les paramètres donnés.
    
    Nécessite que @id contienne l'id du diplome à modifier.
    
    Renvoie true si la mise à jour à réussi, false sinon.
    
    Si la mise à jour a réussi les variables d'instances sont adaptées
    sinon elles restent inchangées.
        
    L'action échoue si les contraintes sur les cours ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def update(params = {})

        if params[:sigle] != nil then params[:sigle] = params[:sigle].gsub(" ","") end
        if params[:facSigle] != nil then params[:facSigle] = params[:facSigle].gsub(" ","") end
        if params[:root_sigle] != nil then params[:root_sigle] = params[:root_sigle].gsub(" ","") end

        d = Diplome.find(@id)

        bck = var_backup()

        @cycle = params[:cycle]
        @sigle = params[:sigle]
        @facSigle = params[:facSigle]
        @root_sigle = params[:root_sigle]


        id = get_root_id(@root_sigle)
        
        if(!check_fields())
            return false
        end

        begin
            d.update_attributes!(
                :cycle => @cycle,
                :sigle => @sigle,
                :facSigle => @facSigle,
                :pmodule_id => id
                )
            return true
        rescue 
            d.errors.full_messages.each do |m|
                @report.write(m,"DiplomeObject update")
            end
            var_restore(bck)
            return false
        end

    end
        
    # Supprime le diplome du modèle.
    # Nécessite que @id contienne l'id de la contrainte à supprimer.
    def destroy()
        d = Diplome.find(@id)
        if d==nil then return false end
        d.destroy
        @inDB = false
        return true
    end

    # Renvoie la liste de tout diplome existant dans le modèle,
    # chargés dans des DiplomeObject
    def self.load_all()
        ds = Diplome.all
        result = []
        ds.each do |d|
            d_o = DiplomeObject.new()
            d_o.load(d.id)
            result << d_o
        end
        return result
    end

private 

    # Vérification des contraintes sur le diplome
    def check_fields()
        id = get_root_id(@root_sigle)

        r = true

        if(@sigle==nil || @sigle.gsub(" ","") == "")
            @report.write("Sigle obligatoire","Contrainte sur le sigle")
            r = false
        elsif(Diplome.find_by_sigle(@sigle.gsub(" ","")) != nil)
            @report.write("Sigle déjà utilisé","Contrainte sur le sigle")
            r = false
        end
        
        if(@root_sigle==nil || @root_sigle.gsub(" ","") == "")
            @report.write("Sigle racine obligatoire","Contrainte sur la racine")
            r = false
        elsif(id==nil)
            @report.write("Sigle racine inexistant dans la base de donnée","Contrainte sur la racine")
            r = false
        elsif(Pmodule.find(id).mtype == "cours")
            @report.write("Sigle racine faisant référence à un cours","Contrainte sur la racine")
            r = false
        end

        return r
    end

    # Renvoie le sigle du module désigné par id (id d'un pmodule)
    def get_root_sigle(id)
        s = Sigle.find_by_pmodule_id(id)
        if(s == nil)
            return nil
        else
            return s.sigle
        end
    end

    def get_root_id(sigle)
        s = Sigle.find_by_sigle(sigle)
        if(s == nil)
            return nil
        else
            return s.pmodule_id
        end
    end

    # Renvoie un dictionnaire contenant la valeur actuelles des variables d'instance 
    def var_backup()
        backup = {}
        backup[:cycle] = @cycle
        backup[:sigle] = @sigle
        backup[:facSigle] = @facSigle
        backup[:root_sigle] = @root_sigle
        backup[:id] = @id
        return backup
    end

    # Modifie les variables d'instance en fonction du dictionnaire "backup"
    def var_restore(backup)
        @cycle = backup[:cycle]
        @sigle = backup[:sigle]
        @facSigle = backup[:facSigle]
        @root_sigle = backup[:root_sigle]
        @id = backup[:id]
    end

end