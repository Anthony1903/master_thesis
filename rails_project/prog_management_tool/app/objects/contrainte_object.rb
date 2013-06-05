# encoding: utf-8


class ContrainteObject
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        # extend, include & persisted? : requis pour pouvoir lier controller et view par "form_for"

    attr_accessor :target, :cond, :effet, :id, :inDB, :report

    def initialize(params = nil) 
        if(params == nil) then params = {} end
        @target = params[:target].to_s.gsub(" ","")
        @cond = format_expr(params[:cond])
        @effet = format_expr(params[:effet])
        @inDB = false
        @report = Report.new()
    end
    
    # Modification des variables d'instances
    def update_params(params)

        if(params[:target] != nil)
            @target = params[:target]
        end
        if(params[:cond] != nil)
            @cond = params[:cond]
        end
        if(params[:effet] != nil)
            @effet = params[:effet]
        end

    end

    # Renvoie "string" tel qu'il existe exactement 1 espace
    # entre les différents symboles
    def format_expr(string)

        if string == nil then return "" end
        result = string

        sym = LogicalExpression.symbols()
        sym.concat(ChoiceConstraintsChecker.spec_symbols())
        sym.each do |s|
            result = result.gsub(s, " " + s + " ")
        end
        
        result = result.split(" ").join(" ")
        result = result.gsub("| |","||")
        result = result.gsub("& &","&&")

        return result

    end

    # Renvoie true si l'objet est présent dans la base de donnée
    def persisted?
        return @inDB
    end

    # Chargement de la contrainte désignée par "id", dans le présentateur
    def load(id)
        
        c = Contrainte.find(id)
        if(c==nil) then return false end

        s = Sigle.find_by_pmodule_id(c.pmodule_id)
        if(s==nil)
            @target = "*" 
        else
            @target = s.sigle
        end

        @cond = c.cond
        @effet = c.effet
        @id = c.id
        @inDB = true

        return true

    end

=begin

    Sauvegarde de la contrainte dans le modèle, renvoie l'id de la nouvelle
    contrainte, ou -1 si la sauvegarde a échoué.

    L'action échoue si les contraintes sur les entités "contraintes" ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def save()

        if !check_constraints(@target, @cond, @effet) then 
            return - 1 
        end

        # Si la cible est "*", l'identifiant du module associé -1.
        if(@target == "*")
            id = -1
        else
            s = Sigle.find_by_sigle(@target)    
            id = s.pmodule_id
        end
        
        c = Contrainte.new(
            :pmodule_id => id,
            :cond => @cond,
            :effet => @effet
            )

        begin
            r = c.save!()
            @id = c.id  
            @inDB = true
            return c.id 
        rescue
            c.errors.full_messages.each do |m|
                @report.write(m,"ContrainteObject save")
            end
            return -1
        end

    end

=begin
    
    Met à jour la contrainte dans le modèle depuis les paramètres donnés.
    
    Nécessite que @id contienne l'id de la contrainte à modifier.
    
    Renvoie true si la mise à jour à réussi, false sinon.
    
    Si la mise à jour a réussi les variables d'instances sont adaptées
    sinon elles restent inchangées.

    L'action échoue si les contraintes sur les entités "contraintes" ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def update(params = {})

        params[:target] = params[:target].to_s.gsub(" ","")
        params[:cond] = format_expr(params[:cond])
        params[:effet] = format_expr(params[:effet])

        if !check_constraints(params[:target], params[:cond], params[:effet]) then 
            return false

        end

        c = Contrainte.find(@id)

        bck = var_backup()

        @target = params[:target]
        @cond = params[:cond]
        @effet = params[:effet]

        if(@target == "*")
            id = -1
        else
            s = Sigle.find_by_sigle(@target)    
            id = s.pmodule_id   
        end

        begin
            r = c.update_attributes!(
                :pmodule_id => id,
                :cond => @cond,
                :effet => @effet)
            return true
        rescue 
            c.errors.full_messages.each do |m|
                @report.write(m,"ContrainteObject update")
            end
            var_restore(bck)
            return false
        end

    end
        
    # Supprime la contrainte du modèle.
    # Nécessite que @id contienne l'id de la contrainte à supprimer.
    def destroy()
        c = Contrainte.find(@id)
        if c==nil then return false end
        c.destroy
        @inDB = false
        return true
    end

    # Renvoie la liste de toutes contraintes existantes dans le modèle,
    # chargés dans des ContrainteObject
    def self.load_all()
        cs = Contrainte.all
        result = []
        cs.each do |c|
                co = ContrainteObject.new()
                co.load(c.id)
                result << co
        end
        return result
    end

private 

    # Renvoie un dictionnaire contenant la valeur actuelles des variables d'instance 
    def var_backup()
        backup = {}
        backup[:target] = @target
        backup[:id] = @id
        backup[:cond] = @cond
        backup[:effet] = @effet
        return backup
    end

    # Modifie les variables d'instance en fonction du dictionnaire "backup"
    def var_restore(backup)
        @target = backup[:target]
        @id = backup[:id]
        @cond = backup[:cond]
        @effet = backup[:effet]
    end

    # Vérifie les contraintes sur les arguments.
    def check_constraints(target, condition, effet)
        params = {}
        params[:target] = target
        params[:cond] = condition
        params[:effet] = effet
        tmp = ContrainteObject.new(params)

        ccc = ChoiceConstraintsChecker.new(tmp)
        r = ccc.check_all()
        ccc.report.list.each do |line|
                @report.write(line,"ContrainteObject check des contraintes")
        end 
        
        return r
    end

end