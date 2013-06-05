# encoding: utf-8

class DbStructuralConstraintsChecker < StructuralConstraintsChecker

=begin
        
    Voire StructuralConstraintsChecker pour plus d'explications

=end

    def check_credits_children()
        if @target.mtype == "cours" then return true end    
        result = true 

        # Crée une liste de contenu
        children_modules = []
        @target.get_content_array.each do |s, a, o|
            sigle = Sigle.find_by_sigle(s)
            if sigle == nil then return false end
            id = sigle.pmodule_id
            if(Pmodule.find_by_id(id).mtype == "cours")
                mod = CoursObject.new()
            else
                mod = EnsembleObject.new()
            end
            mod.load(id)
            children_modules << mod
        end

        # Ne check pas les crédits si l'ensemble n'a pas de contenu (ensemble inachevé)
        if(children_modules.size > 0)
            result = check_credits_children_glob(@target, children_modules)
        end

        return result
    end

    # Effectue check_credits_children sur les parents de target, prennant en compte
    # target à a place de son éventuelle version dans la base de donnée. Permet de vérifier
    # lors d'une mise à jour que le changement de crédits ne pose aucun problème au parents existants.
    def check_credits_parent()
        
        s = Sigle.find_by_sigle(@target.sigles_array[0])

        # Si le module n'est pas encore dans la base de donnée, il n'a pas de parent,
        # la contrainte est vérifiée.
        if(s==nil)
            return true
        end

        # Vérification que le module target, sachant qu'une ancienne version est dans la
        # DB, peut-être sauvegardée vis à vis des contraintes sur les crédits de ses.

        id = s.pmodule_id
        ecs = EnsembleContenu.find_all_by_contenu_id(id)
        
        # Check pour tous les parents
        ecs.each do |ec|
            parent = EnsembleObject.new()
            parent.load(ec.pmodule_id)
            db_scc = DbStructuralConstraintsChecker.new(parent)
            if(!check_credits_parent_aux(parent))
                return false
            end
        end

        return true
    end

    def check_loops()
        if @target.mtype == "cours" then return true end    

        # Initialise le chemin
        path = [@target.sigles_array[0]]

        # Pour chaque enfant, lance une recherche
        @target.get_content_array.each do |s, a, o|
            r, trace = recursive_check_loops(s, path)
            if(!r)
                @report.write("Introduction de cycle ("+trace.join("->")+")", $structural_category)
                return false
            end
        end
        
        return true
    end

    def check_strict_credits_on_instance()
        if(@target.creditsMax != @target.creditsMin)
            return true
        else
            r = DbStructuralConstraintsChecker.check_strict_credits(@target, @target.creditsMax)
            if(!r)
                @report.write("Le contenu de ce module ne permet pas d'atteindre les crédits spécifiés.", $structural_category)
                return false
            else
                return true
            end
        end
    end

    def get_content_sigles(sigle)
        s = Sigle.find_by_sigle(sigle)
        if s==nil then return false end
        
        id = s.pmodule_id
        if Pmodule.find(id).mtype == "cours" then return nil end

        # Liste tous les sigles contenus depuis l'indentifiant correspondant à "sigle"
        res = []
        EnsembleContenu.find_all_by_pmodule_id(id).each do |ec|
            res << Sigle.find_by_pmodule_id(ec.contenu_id).sigle 
        end

        return res
    end


    def self.check_strict_credits(mod, value)
        
        if mod == nil then return nil end

        if(mod.mtype == "cours")
            return mod.creditsMax == value
        elsif(mod.get_content_array.empty?) 
            # Si ensemble de contenu vide, se base sur créditsMin et créditsMax uniquement
            return mod.creditsMax >= value && mod.creditsMin <= value
        else
        
            children_array = make_children_array(mod)

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
                    else   # Sinon, vérification récursive sur le module
                        res &= check_strict_credits(children_array[i][0], list[i])
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
    
    # Renvoie true si le parent, compte tenu du module target qui est modifié dans son contenu,
    # Respecte toujours les contraintes sur les crédits.
    def check_credits_parent_aux(parent)
        result = true 

        if(parent.kind_of?(EnsembleObject))

            # Liste les contenus depuis la DB et la cible
            children_modules = build_children_list(parent)
            
            # Vérification des crédits en fonction de la liste
            # Ne check pas les crédits si l'ensemble n'a pas de contenu (ensemble inachevé)
            if(children_modules.size > 0)
                # Utilise un rapport temporaire pour ne pas garder d'autres informations sur le module parent
                # dans le rapport du checker
                report_bck = Report.new()
                report_bck.merge(@report)
                @report.erase()
                result = check_credits_children_glob(parent, children_modules)

                @report.list.each do |line|
                    report_bck.write("Check de la structure des parents : " + line, $structural_category)
                end
                @report = report_bck
            end

        end

        return result
    end

    # Renvoie la liste des modules contenus par "parent", ou le module
    # correspondant à "target" est remplacé par "target"
    def build_children_list(parent)
        children_modules = []
        # Liste les contenus depuis la DB
        parent.get_content_array.each do |s, a, o|
            if(!@target.sigles_array.include?(s))
                sigle = Sigle.find_by_sigle(s)
                if sigle == nil then return false end
                id = sigle.pmodule_id
                if(Pmodule.find_by_id(id).mtype == "cours")
                    mod = CoursObject.new()
                else
                    mod = EnsembleObject.new()
                end
                mod.load(id)
                children_modules << mod
            else
                # Ajout du module target a la place de son équivalant dans la DB
                children_modules << @target
            end
        end
        return children_modules
    end
    
    # Renvoie, depuis un module, un tableau contenant tout les modules contenus par ce dernier.
    # Chaque élément du tableau est une paire <module, obligatoire>, où "obligatoire" est un booléen 
    # représentant le caractère obligatoire ou non du module dans le contenu.
    def self.make_children_array(mod)
        if mod == nil then return nil end
        children_array = []

        if(mod.mtype == "cours")
            return children_array
        else

            mod.get_content_array.each do |s, a ,o|
                sigle = Sigle.find_by_sigle(s)
                if sigle == nil then return :child_miss_error end
                if(Pmodule.find(sigle.pmodule_id).mtype == "cours")
                    tmp_mod = CoursObject.new()
                else
                    tmp_mod = EnsembleObject.new()
                end
                tmp_mod.load(sigle.pmodule_id)
                children_array << [tmp_mod, o]
            end
            return children_array

        end

    end

end