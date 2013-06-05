# encoding: utf-8

require 'module_loader'
require 'csv_loader'

class EnsembleLoader < ModuleLoader
    

=begin

    Particuliérisation de load_module dans csv_loader.rb.
    Lire la description de cette dernière pour plus d'informations.

    Cas particulier : en cas de manque d'information, suite au fait que "EPL_grp" fait référence à un identifiant 
    n'étant pas répertorié dans "activite", créer un EnsembleObject de type inconnu, reprennant le peu d'informations 
    extraites de "EPL_grp".

=end
    def load_an_ensemble(params, extern_id, report, force = false)

        # Si force = false, remplis params depuis @hashes et extern_id, sinon, utilisera params tels quels
        if(!force)

            # Obtient une liste des éléments contenus par l'ensemble
            content = list_content(extern_id, report)
            act = @hashes["activites"][extern_id]

            # Cas de l'ensemble inconnu
            if(act == nil || act[0] == nil) 
                report.write("Impossible de charger cet ensemble, aucune correspondance dans la table 'activites' (table de description des modules)","error")
                fill_unknown(params, extern_id, report)
                return false
            else
                act = act[0]
                set_ensemble_params(params, act, report, content, extern_id)
            end

        else

            # Si force = true, mais que le contenu est vide, écrit un warning dans le rapport
            if(params[:contenu]==nil || params[:contenu].gsub(" ","") == "")
                report.write("Module de type 'ensemble' n'ayant aucun contenu","warning")
            end

        end
        
        return ModuleLoader.auto_save(params, report, force)

    end

private

    # Essaie de créer un module sans nom depuis les données présentes dans EPL_grp
    def fill_unknown(params, extern_id, report)

        params[:mtype] = "ensemble"
        params[:intitule] = "Module inconnu"
        params[:langue] = "fr-angl"
        params[:sigles] = build_sigle(extern_id)
        params[:creditsMin] = 0
        params[:creditsMax] = 0
        report.write("Module créé en tant que module inconnu (manque d'informations)", "error")
                        
        @hashes["EPL_grp"].each do |grps|
            grps.each do |grp|
                if(!grp.kind_of?(Array))
                    grp = [grp]
                end
                grp.each do |g|
                    if(g["NUM_GRP"]==extern_id.to_s)
                        params[:creditsMin] = g["POIDS_RELATIF"].to_i
                        params[:creditsMax] = g["POIDS_RELATIF"].to_i
                        return
                    end
                end
            end 
        end 
    
    end

    # Renvoie une liste de pair <id, obligatoire> représentant le contenu de l'ensemble
    # d'identifiant "extern_id". "id" est l'extern_id d'un autre module, obligatoire contient
    # la valeur du champ permettant de savoir si le contenu est obligatoire ou non dans ce cas.
    def list_content(extern_id, report)
        content = []
        if(@hashes["EPL_grp"][extern_id]==nil) 
            report.write("Module de type 'ensemble' n'ayant aucun contenu","warning")
        else
            @hashes["EPL_grp"][extern_id].each do |row|
                content << [row["NUM_GRP"], row["LIEN_OBLIG"]]
            end
        end
        return content
    end 


    def set_creditsMin(params, act, report)
        if(CSVLoader.valid_field?(act["POIDS"]))
            params[:creditsMin] = act["POIDS"].to_i
        end

        if(act["CONTRAINTE1"]=="Min" && CSVLoader.valid_field?(act["CONTRAINTE2"]))
            params[:creditsMin] = act["CONTRAINTE2"].to_i
        end

        if (params[:creditsMin] == nil)
            params[:creditsMin] = 0
            report.write("CreditsMin non spécifiés","warning")
        end
    end

    def set_creditsMax(params, act, report)
        if(CSVLoader.valid_field?(act["POIDS"]))
            params[:creditsMax] = act["POIDS"].to_i
        end

        if(act["CONTRAINTE4"]=="Max" && CSVLoader.valid_field?(act["CONTRAINTE5"]))
            params[:creditsMax] = act["CONTRAINTE5"].to_i
        end

        if (params[:creditsMax] == nil)
            params[:creditsMax] = params[:creditsMin]
            str = "CreditsMax non spécifiés"
            report.write(str,"warning")
        end
    end

    def set_commentaire(params, act)
        params[:commentaire] = act["REM_FAC"]
    end

    # Retrouve le module de la base de donnée de l'application,
    # depuis l'identifiant externe (lié à @hashes), puis le renvoie
    def retrieve_pmodule(extern_id)
        sigle = build_sigle(extern_id)
        intern_id = PmoduleObject.id?(sigle)
        if(intern_id==nil)
            return nil
        else
            pm = PmoduleObject.new()
            pm.load_pm(intern_id)
            return pm
        end
    end

    # Déduit la valeur des crédits maximum et minimum d'un ensemble depuis son contenu
    # et le fait que certains modules y soient obligatoire ou non.
    def deduce_credits(params, act, report, content)
        max = 0
        min = 0

        # Parcours du contenu
        content.each do |c, o|

            # Récupération de l'activité, le module contenu
            tmp = @hashes["activites"][c]
            if (tmp != nil)

                tmp = tmp[0]
                eid = tmp["NUM_ELE"]

                # Retrouve le module contenu, tel que sauvegardé dans la base de donnée 
                # (tout contenu est sauvegadé avant son conteneur)
                pm = retrieve_pmodule(eid)
                if(pm!=nil)
                    # Si obligatoire, ajoute les creditsMin à la somme
                    if(o == "1") 
                        min += pm.creditsMin
                    end
                    # Ajoute les creditsMax à la somme dans tous les cas
                    max += pm.creditsMax
                else
                    report.write("Impossible de déduire les crédits, certains contenus sont manquant dans la base de donnée","warning")
                    params[:creditsMin] = 0
                    params[:creditsMax] = 0
                    return
                end

            end
        end 

        if(max == 0)
            report.write("CreditsMax = 0 (malgré la déduction des crédits par rapports au contenu)","warning")
        end

        params[:creditsMin] = min
        params[:creditsMax] = max

    end

    # Compose le champs "contenu" de l'EnsembleObject, depuis des données précédemment extraites
    # de @hashes. content doit être une liste construite par "list_content()".
    def set_content(params, act, report, content, extern_id)
        params[:contenu] = ""

        # Parcours le contenu
        content.each do |c, o|

            # Retrouve le sigle associé au contenu
            sigle = build_sigle(c)

            # Retrouve l'année, et la caractère obligatoire ou non, associée à l'ensemble
            grp = @hashes["EPL_grp"][extern_id]
            fgrp = grp[0]
            year = fgrp["NIVEAU"]
            obligatoire =  (o == "1")
            if(year == nil || year.gsub(" ","") =="")
                year = "1-2-3"
            else
                t = year.gsub("","-")
                year = t[1..t.length-2]
            end

            # Ajoute le contenu depuis les données obtenues
            if(params[:contenu] != "")
                params[:contenu] += ", "
            end
            params[:contenu] += sigle.to_s + " " + year.to_s + " " + obligatoire.to_s

        end 
    end

    def set_ensemble_params(params, act, report, content, extern_id)
        params[:mtype] = "ensemble"
        
        set_module_params(params, act, report)             
        set_creditsMin(params, act, report)
        set_creditsMax(params, act, report)
        set_commentaire(params, act)

        # Si les crédits ne sont pas spécifiés, les déduits depuis le contenu, 
        # et écrit un warning dans le rapport
        if(params[:creditsMax]==0) 
            report.write("Déduction des crédits par rapport au contenu", "warning")
            deduce_credits(params, act, report, content)
        end

        set_content(params, act, report, content, extern_id)
    end

end