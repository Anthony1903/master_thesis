# encoding: utf-8

class CompositorsController < ApplicationController

    def index()
        @title = "Composition de programme"
    end

=begin

    Créer l'arborescence nécessaire à la composition de programme.

    Paramètre attendu : 
        "sigle" : indique la racine du module à charger

=end
    def show()
        
        @title = "Composition de programme"
        @sigle = params[:sigle]
        @report = Report.new 

        if(@sigle != nil)

            id = PmoduleObject.id?(@sigle)

            # Vérifie que le sigle existe bien
            if(id == nil)

                flash[:error] = "Le sigle n'est pas reconnu"
                render 'index'

            # Vérifie que le sigle n'est pas lié à un cours
            elsif(Pmodule.find(id).mtype == "cours")

                flash[:error] = "Le sigle ne peut être celui d'un cours"
                render 'index'

            else

                # Charge l'ensemble
                eo = EnsembleObject.new()
                eo.load(id)
                new_node = SelectionNode.new(eo)

                # Construit l'arborescence
                SelectionTree.build_tree(new_node)
                $tree_root = new_node

                flash[:success] = @sigle + " correctement chargé"

            end

        else
            flash[:error] = "Un sigle doit être spécifié"
            render 'index'
        end

    end

=begin

    Vérifie les contraintes portant sur les sélections, depuis celles
    réalisées, sur l'arbre de racine $tree_root, initialié lors de "show"

    Paramètre attendu : 
        "selected" : liste de sigle considérés comme sélectionnés

=end
    def check

        @title = "Composition de programme"
        
        # Récupération des sélections par quadri
        @selected_q1 = params[:selected_q1].to_a
        @selected_q2 = params[:selected_q2].to_a
        @selected_q3 = params[:selected_q3].to_a
        @selected_q4 = params[:selected_q4].to_a
        @selected_q5 = params[:selected_q5].to_a
        @selected_q6 = params[:selected_q6].to_a

        # Calcul des sommes pour chaque ensemble de sélections
        @sum_q1 = compute_sums_on_quadri(@selected_q1)
        @sum_q2 = compute_sums_on_quadri(@selected_q2)
        @sum_q3 = compute_sums_on_quadri(@selected_q3)
        @sum_q4 = compute_sums_on_quadri(@selected_q4)      
        @sum_q5 = compute_sums_on_quadri(@selected_q5)
        @sum_q6 = compute_sums_on_quadri(@selected_q6)

        # @selected = union de toutes les sélections
        @selected = @selected_q1 |@selected_q2 | @selected_q3 | @selected_q4 | @selected_q5 | @selected_q6 
        @selected = @selected.uniq

        @report = Report.new()

        # Crée une copie
        bck = $tree_root.clone()

        # Sélections pour le checker
        select_nodes(@selected, $tree_root) 

        # Application des substitutions
        scc = SelectionConstraintsChecker.new($tree_root, $tree_root) 
        scc.check_and_apply_choice_constraints()    

        # Resélections après substitutions
        select_nodes(@selected, $tree_root) 

        # Recheck après substitutions
        scc = SelectionConstraintsChecker.new($tree_root, $tree_root) 
        scc.check_and_apply_choice_constraints()    
        @report.merge(scc.report)

        $tree_root.list_nodes.each do |node|
            scc = SelectionConstraintsChecker.new(node, $tree_root) 
            scc.check_mandatory_content()
            scc.check_credits()
            @report.merge(scc.report)
        end

        render 'show'
        
        # Replace la copie initiale
        $tree_root = bck

    end

private

    # Sélectionne tout les modules dont le sigle du module parent et le sigle du module contenu
    # correspondent à une des paires de "list", qui sont présent dans l'arbre de racine "tree".
    # Lorsqu'une feuille est sélectionnée, tout ses ancètres le sont aussi.
    def select_nodes(list, tree)

        if(list!=nil)
            list.each do |pair|
                arr_pair = pair.split(" ")
                selected_sigle = arr_pair[0] 
                selected_parent = arr_pair[1]

                p_n_pairs = SelectionTree.find_nodes(tree, selected_sigle)
                p_n_pairs.each do |p, n|

                    if(p.data.sigles_array.include?(selected_parent) && n.data.sigles_array.include?(selected_sigle))
                        n.select
                        if(p!=nil)
                            p.select
                            select_parents_recursively(p.data.sigles_array[0], tree)
                        end
                    end

                end

            end
        end

    end

    # Sélectionne tout les parents du module de sigle "sigle" dans l'arbre
    # de racine "tree"
    def select_parents_recursively(sigle, tree)

        p_n_pairs = SelectionTree.find_nodes(tree, sigle)
        if(p_n_pairs != :error)
            p_n_pairs.each do |p, n|
                if(p!=nil)
                    p.select
                    select_parents_recursively(p.data.sigles_array[0], tree)
                end
            end
        end

    end

    # Renvoie la somme des crédits min et max des modules sélectionnés par la liste argument
    # Résultat sous forme de tableau [min, max]
    def compute_sums_on_quadri(selected_list)
        sum_min = 0
        sum_max = 0
        if selected_list == nil then return nil end
        selected_list.uniq.each do |pair|
            arr_pair = pair.split(" ")
            sigle = arr_pair[0] 
            id = PmoduleObject.id?(sigle)
            if id == nil then return nil end
            o = PmoduleObject.new()
            o.load_pm(id)
            sum_min += o.creditsMin.to_i
            sum_max += o.creditsMax.to_i
        end
        return [sum_min, sum_max]
    end

end