# encoding: utf-8


=begin

    Regroupe les parties communes à au cours_loader et là l'ensemble_loader.
    
=end

class ModuleLoader

    def initialize(hashes)
        @hashes = hashes
    end

    def set_module_params(params, act, report)

        set_intitule(params, act)
        set_language(params, act)
        set_sigles(params, act)
        set_dptCharge(params,  act)
        set_validite(params,  act)

    end

    # Donne un sigle unique pour le module d'id "extern_id"
    # Si le sigle classique ne peut être construit suite à un manque
    # d'information, le sigle sera UNKNOWN_<extern_id>.
    def build_sigle(extern_id)
        tmp = @hashes["activites"][extern_id.to_s]
        sigle = nil
        if(tmp==nil || tmp[0]==nil)
            sigle = "UNKNOWN_"+extern_id.to_s
        else
            tmp = tmp[0]
            sigle = tmp["SIGLE_ELE"]
            sigle += tmp["CNUM"]
            sigle += tmp["SUBDIVISION"]
        end
        return sigle
    end

private

    def set_intitule(params, act)
        params[:intitule] = act["INTIT_COMPLET"]
    end

    def set_language(params, act)
        if(act["LANGUE"] == "E")
            params[:langue] = "angl"
        else
            params[:langue] = "fr"
        end
    end

    def set_sigles(params, act)
        params[:sigles] = build_sigle(act["NUM_ELE"])
    end

    def set_dptCharge(params,  act)
        params[:dptCharge] = act["DPT_CHARGE"]
    end

    def set_validite(params, act)
        params[:validite] = act["VALIDITE"].to_i
    end

=begin

    Sauvegarde ou met à jour automatiquement un module en fonction des params et de la DB.

        force = false : (phase 1 le l'import d'un module)
            => Si une mise à jour est nécessaire, renvoie false avec un avis de mise  
               à jour placé dans le rapport.
    
        force = true : (phase 2 le l'import d'un module)
            => Si une mise à jour est nécessaire, tente la mise à jour.

    Cette méthode utilise le gestionnaire de version pour que les paramètres soient 
    adaptés au champ validité.

=end
    def self.auto_save(params, report, force_update)

        # Récupération de l'éventuel id d'un module correspondant en DB
        
        params = VersionManager.params_according_to_validity(params)
        intern_id = PmoduleObject.id?(params[:sigles][0]) # (sigles déjà en version tableau)
     
        # Cas où le module n'existe pas encore
        if(intern_id == nil)

            # Tentative de sauvegarde et complétion du rapport
            if(VersionManager.save(params, report))
                return true
            else
                return false
            end

        # Cas où un module de même sigle existe déjà
        else 

            # Chargement du module existant
            existing_mod = VersionManager.create_module(params)
            existing_mod.load(intern_id)

            # Si les deux sont les mêmes, renvoie true
            if(existing_mod.compaire(params) == nil)
                return true

            # Sinon, si force est à true, tente la mise à jour, 
            elsif(force_update)
                return VersionManager.update(intern_id, params, report, true)
            
            # Sinon renvoie false et écrit un avis de mise à jour
            else
                report.write("Avis de mise à jour ","update")
                return false
            end
        
        end

    end 

end