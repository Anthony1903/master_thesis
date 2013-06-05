# encoding: utf-8

class ImportManagersController < ApplicationController

    $csv_loader = CSVLoader.new()

    def index
        @title = "Etat du gestionnaire d'imports"
    end

=begin

  Initialise le csv_loader et lance le chargement des fichiers. 

  Paramètres attendus:
    "file_names" : dictionnaire contenant les noms des fichiers à charger 
  
=end
    def load_files()

        if(params[:file_names] != nil) # Sinon, utilise les noms par défaut
            $csv_loader = CSVLoader.new(params[:file_names])
        end

        @result, info, fname = $csv_loader.load_files

        if(!@result)
            if(info == :read_error)
                flash[:error] = fname.to_s + " ne peut être lu."
            elsif(info == :format_error)
                flash[:error] = fname.to_s + " ne respecte pas le format pris en charge. Toute ligne 
                    doit contenir exactement autant d'éléments que la première ligne du fichier."
            end
        end

        index()
        render 'index'

    end

=begin

  Lance le chargement des modules suivants pour la racine actuelle, jusqu'à la fin de l'import, ou que
  l'intervention de l'utilisateur est nécessitée. 
  
  Si load_next est invoqué sur une nouvelle racine pour la première fois, le paramètre contient 
  l'identifiant de la racine.

  Paramètres attendus:
    "root_selected" : Indique l'identifiant de la racine de la structure à charger lors du premier load_next.

=end
    def load_next()

        @title = "Import"

        # Initialise la pile si première invocation sur la racine
        if(params[:root_selected]!=nil)
            $csv_loader.init_stack(params[:root_selected])
        end

        if(!$csv_loader.files_loaded?)
            flash[:error] = "Impossible de charger les données, les fichiers doivent avoir été chargés au préalable."
            render 'index'
        else

            interruption = false
            @end = false

            # Importe chaque module de la pile, jusqu'à la fin de celle-ci, ou que
            # l'intervention de l'utilisateur est nécessitée. 
            while(!interruption && !@end)
                r = $csv_loader.load_next
                # Cas où toute la pile a été importée
                if(r == :empty) 
                    @end = true
                else
                    set_vars(r)
                    # Cas où l'import s'est effectué correctement
                    if(@flag != "valid") 
                        interruption = true
                        if(@mod.intitule == nil || @mod.intitule.gsub(" ","") == "")
                            @sigle_title = "Rapport (#{@mod.sigles})"
                        else
                            @sigle_title = "Rapport (#{@mod.sigles}, #{@mod.intitule})"
                        end
                    end
                end          
            end

        end

    end

=begin

  Recoit un feedback de l'utilisateur, le transmet au $csv_loader, et invoque load_next
  pour reprendre l'import là ou il a été interrompu.

  Paramètres attendus:
    "keep" : si "true", indique que le feedback est "conserver le module actuel" (lors d'un avis de mise à jour).
    "cours_object" : données des champs que l'utilisateur à pu modifier pour un CoursObject
    "ensemble_object" : données des champs que l'utilisateur à pu modifier pour un EnsembleObject
    
=end
    def feedback() 

        if(params[:keep] != nil)
            $csv_loader.set_feedback(:keep, nil)
        else
            if(params[:ensemble_object] != nil)
                params[:ensemble_object][:mtype] = "ensemble"
                $csv_loader.set_feedback(params[:ensemble_object], nil)
            elsif( params[:cours_object] != nil)
                params[:cours_object][:mtype] = "cours"
                $csv_loader.set_feedback(params[:cours_object], nil)
            end
        end

        load_next()

        if($csv_loader.files_loaded?) # S'assure qu'il n'y aura jamais de double render
            render 'load_next'
        end

    end

=begin
    
    Réinitilise la pile en fonction de la racine actuellement prise en compte. 

    Aucun paramètre attendu

=end
    def init_stack()
        if(!$csv_loader.files_loaded?)
            flash[:error] = "Impossible d'initialiser la pile, les fichiers doivent avoir été importés au préalable"
        else
            $csv_loader.reinit_stack()
            flash[:success] = "Pile réinitialisée"
        end
        render 'index'
    end

private

    # Extrait les éléments formant le résultat de $csv_loader.load_next, et les
    # place dans des variables
    def set_vars(r)

        @flag = r[:flag]
        @id = r[:id]
        @report = r[:report]
        @mod = r[:mod]
        @current = r[:current]
        @stack_initial_size = r[:stack_initial_size]    
        @stack_current_size = r[:stack_current_size]

    end

end
