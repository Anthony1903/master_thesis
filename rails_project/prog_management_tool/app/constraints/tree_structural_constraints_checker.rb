# encoding: utf-8

class TreeStructuralConstraintsChecker < StructuralConstraintsChecker

=begin
        
    Voire StructuralConstraintsChecker pour plus d'explications

=end    

    # target est un noeud contenant un module, et root la racine d'un arbre contenant target
    def initialize(target, root)
        super(target)
        @root = root
    end

    def check_credits_children()
        if @target.data.mtype == "cours" then return true end   
        result = true 

        # Crée une liste de contenu depuis les noeuds de l'arbre
        children_modules = []
        @target.children.each do |n|
            children_modules << n.data
        end

        result = check_credits_children_glob(@target.data, children_modules)

        return result
    end

    # Effectue check_credits_children sur chacun des parents de target
    def check_credits_parent()
        # Récupère tous les parents
        p_n_pairs = Tree.find_nodes(@root, @target.data.sigles_array()[0])
        if(p_n_pairs != :error && !p_n_pairs.empty?)
            result = true
            p_n_pairs.each do |p, n|
                if(p != nil) # Si = nil, aucun parent n'existe
                    # Crée un checker et vérifie les crédits sur les enfants du parent
                    tree_scc = TreeStructuralConstraintsChecker.new(p, @root)
                    result &= tree_scc.check_credits_children()
                    tree_scc.report.list.each do |line|
                        @report.write("Check de la structure des parents : " + line, $structural_category)
                    end
                end
            end
            return result
        else
            return !p_n_pairs ==:error 
        end
    end

    def check_loops()
        if @target.data.mtype == "cours" then return true end   
        
        # Initialise le chemin
        path = [@target.data.sigles_array[0]]

        # Pour chaque enfant, lance une recherche
        @target.data.get_content_array.each do |s, a, o|
            r, trace = recursive_check_loops(s, path)
            if(!r)
                @report.write("Introduction de cycle ("+trace.join("->")+")", $structural_category)
                return false
            end
        end

        return true
    end

    def check_strict_credits_on_instance()
        if(@target.data.creditsMax != @target.data.creditsMin)
            return true
        else
            r = TreeStructuralConstraintsChecker.check_strict_credits(@target, @target.data.creditsMax, @root)
            if(!r)
                @report.write("Le contenu de ce module ne permet pas d'atteindre les crédits spécifiés.", $structural_category)
                return false
            else
                return true
            end
        end
    end

    def get_content_sigles(sigle) 
        # Le premier noeud trouvé suffit, l'ensemble a le même contenu peu importe le noeud qu'il occupe
        # De plus, appeler find_nodes, si une boucle existe, ferais entrer dans une boucle infinie.
        n = Tree.find_node(@root, sigle) # pas find_nodes!
        if(n==nil || n==:error || n.data.mtype == "cours")
            return nil
        else
            res = []
            n.data.get_content_array.each do |s, a, o|
                res << s
            end
            return res
        end
    end

    def self.check_strict_credits(node, value, root)
        
        if node == nil then return nil end

        if(node.data.mtype == "cours")
            return node.data.creditsMax == value
        elsif(node.data.get_content_array.empty?)
            # Si ensemble de contenu vide, se base sur créditsMin et créditsMax uniquement
            return node.data.creditsMax >= value && node.data.creditsMin <= value
        else
        
            children_array, nodes_array = make_children_array(node)
            if children_array == :child_miss_error || nodes_array == nil then return :child_miss_error end

            # Calcul de toutes les combinaisons de sommes de crédits possibles
            ac = all_combinations(children_array)

            # Garde les combinaisons dont la somme vaut la valeur recherchée
            fc = filter_on_sum(ac, value)

            # Teste les combinaisons restantes  
            fc.each do |list|
                res = true
                # Parcours de la combinaison 
                (0..(list.size-1)).each do |i|

                    # Pour chaque valeur de la combinaison, vérifie l'enfant associé sait bien atteindre les crédits 
                    if(list[i] == 0 && children_array[i][1] == false)   # si valeur demandée = 0 et contenu non obligatoire => ok
                        res &= true
                    else
                        c1 = children_array[i][1] == true                                         # si contenu obligatoire
                        c2 = children_array[i][0].creditsMin == children_array[i][0].creditsMax   # et contenu tel que crédits min = max
                        c3 = children_array[i][0].creditsMax == list[i]                           # et contenu crédits = valeur
                        if(c1 && c2 && c3) # alors pas besoin de checher plus loin 
                                           # (structure doit avoir fait cette vérification lors de la sauvegarde du module)
                            res &= true                                                           
                        else # Sinon, vérification récursive sur le module
                            n = nodes_array[i]
                            res &= check_strict_credits(n, list[i], root)
                        end
                    end

                    if !res then break end

                end
                # Si tous les enfants savent atteindre les crédits de la combinaison, renvoie true.
                if res then return true end
            end
        
        end
        
        return false

    end


private

    # Renvoie, depuis un noeud, un tableau contenant tout les modules contenus par le module associé, ainsi
    # qu'un tableau contenant les noeud correspondants au contenu dans le même ordre.
    # Chaque élément du premier tableau est une paire <module, obligatoire>, où "obligatoire" est un booléen 
    # représentant le caractère obligatoire ou non du module dans le contenu.
    def self.make_children_array(node)
        if node == nil then return nil, nil end
        children_array = []
        nodes_array = []

        if(node.data.mtype == "cours")
            return children_array, nodes_array
        else

            node.data.get_content_array.each do |s, a ,o|
                found = false
                node.children.each do |child|
                    if(child.data.sigles_array().index(s)!=nil)
                        children_array << [child.data, o]
                        nodes_array << child
                        found = true
                    end
                end
                if !found then return :child_miss_error, nil end
            end
            return children_array, nodes_array

        end

    end

    
end