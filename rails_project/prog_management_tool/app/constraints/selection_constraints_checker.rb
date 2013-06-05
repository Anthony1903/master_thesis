# encoding: utf-8

# Seul checker concu pour la sélection d'un programme par un étudiant
# Travaille sur un arbre de SelectionNode
class SelectionConstraintsChecker < ConstraintsChecker

    $selection_category = "Contraintes sur sélection" 
    $info = "Informations supplémentaires"  

    # target est un SelectionNode, et tree_root la racine d'un arbre de SelectionNodes
    def initialize(target, tree_root = nil)
        super(target)
        @tree_root = tree_root
    end

    def check_all()
        if !check_credits then return false end
        if !check_mandatory_content then return false end
        if !check_and_apply_choice_constraints then return false end
        return true
    end

    # Si la cible est sélectionnée, alors la somme du contenu sélectionné doit avoir une valeur entrant 
    # dans les bornes de crédits de l'ensemble.
    # Si la condition est vérifiée, ou si target contient un cours, renvoie true, sinon renvoie false. 
    def check_credits()
        
        if(@target.data.mtype == "cours" || @target.data.contenu == nil || @target.data.contenu.gsub(" ","") == "" || !@target.is_selected?)
            return true
        end

        min = @target.data.creditsMin.to_i
        max = @target.data.creditsMax.to_i
        cred = sum_on_selected(@target)
        if(cred >= min && cred <= max)
            return true
        else
            @report.write("La sélection actuelle ne respecte pas les crédits du programme pour le module #{@target.data.sigles_array[0]}", $selection_category)
            return false
        end
    
    end

    # Si la cible est sélectionnée, alors tout le contenu obligatoire doit l'être aussi.
    # Si la condition est vérifiée, ou si target contient un cours, renvoie true, sinon renvoie false. 
    def check_mandatory_content()
        if(@target.data.mtype == "cours" || @target.data.contenu == nil || @target.data.contenu.gsub(" ","") == "" || !@target.is_selected?)
            return true
        end
        result = true
        @target.data.get_content_array.each do |s, a, o|
            if(o)
                @target.children.each do |c|
                    if(c.data.sigles_array.include?(s) && !c.is_selected?)
                        @report.write("Un module obligatoire n'a pas été sélectionné : #{s}", $selection_category)
                        result = false
                    end
                end
            end
        end
        return result
    end

    # Vérifie les contraintes portant sur les choix pour chaque noeud du l'arbre de racine "target", et remplis
    # le rapport en conséquence. Si une substitution doit être effectuée, la méthode l'applique sur l'arbre.
    def check_and_apply_choice_constraints()
        selected_sigles = []
        @target.list_selected_nodes.each do |sn|
            selected_sigles << sn.data.sigles_array[0]
        end

        # Chargement de toutes les contraintes de ce type présents dans la DB
        constrs = ContrainteObject.load_all() 

        # Parcours de chacune d'entre-elle
        constrs.each do |c|
            ccc = ChoiceConstraintsChecker.new(c)

            # Si la contrainte est enclenchée par le contexte (les modules sélectionnés), applique l'effet.
            if(ccc.triggered?(selected_sigles))

                # result = "OK" ou "NOK" en fonction de si la contraine est violée ou non
                result = apply_effects(ccc, selected_sigles) 
                
                # Ecriture d'un message d'information dans les deux cas pour avertir l'utilisateur
                @report.write("[Contrainte enclenchée, portée : #{c.target}, condition : #{c.cond}, effet : #{ccc.extract_effects}, état : #{result}", $info)
            end

        end
        return true
    end

private

    # Renvoie la somme des crédits des modules sélectionnés, présents dans les feuilles de l'arbre de racine "selection_node".
    def sum_on_selected(selection_node)
        sum = 0
        if(selection_node == nil)
            return 0
        else
            selection_node.list_selected_nodes.each do |sn|
                if(sn.children.size == 0 && sn != selection_node)
                    sum += sn.data.creditsMin.to_i
                end
            end
            return sum
        end
    end

    def apply_effects(ccc, selected_sigles)


        res = "OK"

        # Parcours la liste des effets
        ccc.extract_effects.each_pair do |sigle, effect|

            # Cas ou l'effet est "obligatoire", et que le module correspondant n'a pas été sélectionné
            if(effect == true && !selected_sigles.include?(sigle))
                @report.write("Contrainte violée : #{ccc.target.cond} => #{ccc.extract_effects}", $selection_category)
                res = "NOK"
            
            # Cas ou l'effet est "interdit", et que le module correspondant a été sélectionné
            elsif(effect == false && selected_sigles.include?(sigle))
                @report.write("Contrainte violée : #{ccc.target.cond} => #{ccc.extract_effects}", $selection_category)
                res = "NOK"
            
            # Cas ou l'effet est "module vivement encouragé"
            elsif(effect == "E")
                @report.write("#{sigle} : est vivement encouragé", $selection_category)
            
            # Cas ou l'effet est "module nécessitant la réussite d'une test"
            elsif(effect == "T")
                @report.write("#{sigle} : requière la réussite d'un test", $selection_category)
            
            # Cas ou l'effet est "module nécessitant l'approbation de la commission des programmes"
            elsif(effect == "C")
                @report.write("#{sigle} : requière l'approbation de la commission des programmes", $selection_category)
            
            # Cas ou l'effet est une substitution
            elsif(effect.kind_of?(String)) 
            
                # Retrouve tous les noeuds concernés par la substitution
                p_n_pairs = SelectionTree.find_nodes(@tree_root, sigle)
                p_n_pairs.each do |p, n|
                    id = PmoduleObject.id?(effect)
                    if(n!=nil && n!=:error && id!=nil)
                        if(Pmodule.find(id).mtype=="cours")
                            m = CoursObject.new()
                        else
                            m = EnsembleObject.new()
                        end
                        m.load(id)

                        # Remplace le noeud
                        n.data = m
                        n.remove_children()

                        # Construit la hiérarchi desendante (ne devrait pas avoir de boucle car existe dans la DB).
                        SelectionTree.build_tree(n, true, false)
                    else    
                        @report.write("Substitution enclenchée mais impossible de la mettre en pratique", $selection_category)
                        # Ne consistue pas une violation de contrainte, ne devrait pas se produire.
                    end
                end
            
            end
        
        end

        return res

    end

end
