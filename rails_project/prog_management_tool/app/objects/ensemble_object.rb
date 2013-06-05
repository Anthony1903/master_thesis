# encoding: utf-8

class EnsembleObject < PmoduleObject

    attr_accessor :contenu

=begin  
    
    Le contenu d'un ensemble est formé d'une liste de trois éléments
     - le sigle, indiquant le module contenu
     - une année, indiquant durant quelle(s) année(s) le contenu est dispensé
     - un booléen, indiquand si l'élément contenu est obligatoire ou non.

    Le contenu peut prendre différentes formes. Dans le présentateur, il est 
    conservé sous forme de string ou chaque triplet est séparé par une virgule.
    Ex : "un_sigle 1 true, un_second_sigle 1-2 false"
    Ce format facilite la présentation de l'objet par le contrôleur.

    Le contenu peut néanmoins être manipulé, via les méthodes get_content_array et 
    set_content_array, via un tableau. Le contenu est alors un tableau
    de sous-tableaux contenant chacun un triplet. Dans le tableau, le sigle
    et l'année sont des string, mais le booléen est du type booléen
    Ex : [["un_sigle", "1", true], ["un_second_sigle", "1-2", false]]

=end

    def initialize(param = nil)

        if(param == nil) then param = {} end

        if(param[:contenu]==nil) 
            param[:contenu] = ""
        end

        super(param)

        @contenu = param[:contenu]

        @mtype = "ensemble" # Initialise cette variable indépendament de l'input

    end

    # Renvoie un dictionnaire contenant la valeur de chaque variable d'instance
    def extract_params()
        param = extract_params_pm()
        param[:contenu] = get_content_array

        return param
    end

    # Renvoie le contenu sous forme de tableau
    # (est sous forme de string dans la variable d'instance)
    def get_content_array()
        return content_to_array(@contenu)
    end

    # Modifie le contenu depuis une version tableau
    # (est sous forme de string dans la variable d'instance)
    def set_content_array(array)
        result = ""
        array.each do |s, a, o|
            if(result != "")
                result += ", "
            end
            result += s.to_s + " " + a.to_s + " " + o.to_s
        end
        @contenu = result
    end

    # Modification des variables d'instances
    def update_params(params)

        update_params_pm(params)

        if(params[:contenu] != nil)
            if(params[:contenu].kind_of?(Array))
                set_content_array(params[:contenu])
            else
                @contenu = params[:contenu]
            end
        end
    end

    # Renvoie un dictionnaire de paires <:self, :other> reprennant
    # les différences entre les variables d'instances et les paramètres
    # passés en argument. Tout est comparé excepté le status.
    def compaire(other_params)
        param = extract_params()
        result = {}

        param.each_pair do |k, v|
            if(other_params[k] != v && other_params[k].to_s != v.to_s)
                if(k==:contenu)
                    if(content_to_array(v).sort != content_to_array(other_params[k]).sort) # Compare le contenu peu importe la forme
                        result[k] = {:self => v, :other => other_params[k]}
                    end
                elsif(k!=:status)
                    result[k] = {:self => v, :other => other_params[k]} 
                end
            end
        end

        if result.length==0 then return nil end
            
        return result
    end

    # Chargement de l'esnembe désignée par "id" (id du pmodule correspondant au cours)
    # dans le présentateur
    def load(id)
        
        if ((pm = load_pm(id))==nil) then return false end

        ecs = pm.contenu()

        if(ecs==nil) then return false end

        @contenu = ""
        ecs.each do |ec|
            if(@contenu!="") 
                @contenu+=", " 
            end
            @contenu += Sigle.find_by_pmodule_id(ec.contenu_id.to_s).sigle + " " + ec.annee.to_s + " " + ec.obligatoire.to_s
        end

        return true
    end

=begin

    Sauvegarde de l'ensemble dans le modèle, renvoie l'id du nouveau pmodule créé
    ou -1 si la sauvegarde a échoué.
    
    L'action échoue si les contraintes sur les ensembles ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def save()

        pm = nil

        # Check des contraintes après pour permettre la vérifications des champs de se faire avant le reste (plus important)        
        if(!check_constraints(self))
            return -1
        end

        begin
        
            ActiveRecord::Base.transaction do

                pm = save_pm

                if(@contenu==nil)
                    @contenu = ""
                end

                cont = content_to_array(@contenu)

                cont.each do |s, a, o|
                    cc = pm.contenu.new(:contenu_id => Sigle.find_by_sigle(s).pmodule_id, :annee => a, :obligatoire => o)
                    @errors = cc.errors
                    cc.save!
                end 

            end
        
        rescue => e
            return -1
        end

        @id = pm.id # Avant check_constraints car indispensable pour destroy()

        return pm.id
    end

=begin
    
    Met à jour l'ensemble dans le modèle depuis les paramètres donnés.
    
    Nécessite que @id contienne l'id de l'ensemble à modifier.
    
    Renvoie true si la mise à jour à réussi, false sinon.
    
    Si la mise à jour a réussi les variables d'instances sont adaptées
    sinon elles restent inchangées.
        
    L'action échoue si les contraintes sur les ensembles ne sont pas respectées.
    Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
    def update(param = {})

        if(@id==nil) then return false end

        add_default(param)

        bck = var_backup_e()

        @contenu = param[:contenu]
        
        if(@contenu==nil)
            @contenu = ""
        end

        tmp = EnsembleObject.new(param)
        if(!check_constraints(tmp))
            var_restore_e(bck)
            return false
        end 

        begin

            ActiveRecord::Base.transaction do

                pm = update_pm(param)

                pm.contenu.each do |c|
                    @errors = c.errors
                    c.destroy
                end

                cont = content_to_array(@contenu)

                cont.each do |s, a, o|
                    cc = pm.contenu.new(:contenu_id => Sigle.find_by_sigle(s).pmodule_id, :annee => a, :obligatoire => o)
                    @errors = cc.errors
                    cc.save!
                end

            end

        rescue => e
            #puts "=> "+e
            var_restore_e(bck)
            return false
        end

        return true

    end

    # Renvoie la liste de tout ensemble existant dans le modèle,
    # chargés dans des EnsembleObject
    def self.load_all()
        pms = Pmodule.find_all_by_mtype("ensemble")
        result = []
        pms.each do |pm|
                eo = EnsembleObject.new
                eo.load(pm.id)
                result << eo 
        end
        return result
    end

private

    # Renvoie un dictionnaire contenant la valeur actuelles des variables d'instance 
    def var_backup_e()
        backup = var_backup()
        backup[:contenu] = @contenu
        return backup
    end

    # Modifie les variables d'instance en fonction du dictionnaire "backup"
    def var_restore_e(backup)
        var_restore(backup)
        @contenu = backup[:contenu]
    end

    # Renvoie la version "tableau" du contenu
    def content_to_array(cont)
        if(cont.kind_of?(Array))
            return cont
        end
        result = []

        if(cont == nil || cont.gsub(" ","") == "")
            return result
        else
            cont.split(",").each do |tmp|
                r = tmp.split(" ")
                if(r[2] == "true")
                    o = true
                elsif(r[2] == "false")
                    o = false
                end
                r[2] = o
                result << r
            end
        end

        return result
                 
    end

end