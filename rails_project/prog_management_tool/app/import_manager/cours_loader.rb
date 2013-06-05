# encoding: utf-8

require 'module_loader'

class CoursLoader < ModuleLoader
    
=begin

    Particuliérisation de load_module dans csv_loader.rb.
    Lire la description de cette dernière pour plus d'informations.

=end
    def load_a_cours(params, extern_id, report, force = false)
 
        # Si force = false, remplis params depuis @hashes et extern_id, sinon, utilisera params tels quels
        if(!force)
            act = @hashes["activites"][extern_id]

            if(act == nil || act[0] == nil) 
                report.write("Impossible de charger ce cours, aucune correspondance dans la table 'activites' (table de description des modules)", "error")
                return false
            end

            act = act[0]
            set_cours_params(params, act, report)
        end

        return ModuleLoader.auto_save(params, report, force)

    end

private

    def set_credits(params, act, report)
        params[:creditsMax] = act["POIDS"].to_i
        params[:creditsMin] = act["POIDS"].to_i
        if(params[:creditsMin] == 0) 
            report.write("Credits = 0","warning")
        end
    end

    def set_durees(params,  act, report)
        params[:dureeCours] = act["VOL_TOT1"].to_f
        params[:dureeTP] = act["VOL_TOT2"].to_f
    end

    def set_quadri(params,  act, report)
        duree_Q1 = act["VOL_HORPQ1"]
        duree_Q2 = act["VOL_HORSQ1"]
        if(duree_Q1 != "")
            params[:quadri] = 1
        elsif(duree_Q2 != "")
            params[:quadri] = 2
        else
            params[:quadri] = nil
        end
    end

    def set_professeur(params, act)
        profs = []
        @hashes["prof"].each_value do |p|
            p = p[0]
            if(p["NUM_ELE"] == act["NUM_ELE"])
                profs << params[:professeur] = p["NOM"].to_s + " " + p["PRENOM"].to_s
            end
        end
        params[:professeur] =  profs.sort.join(", ")
    end

    def set_cours_params(params, act, report)
        params[:mtype] = "cours"
        set_module_params(params, act, report)
        set_credits(params, act, report)
        set_durees(params, act, report)
        set_quadri(params, act, report)
        set_professeur(params, act)
    end
end