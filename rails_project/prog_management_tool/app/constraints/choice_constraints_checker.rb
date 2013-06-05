# encoding: utf-8

class ChoiceConstraintsChecker < ConstraintsChecker


    $choice_category = "Contraintes sur choix"

=begin

    ChoiceConstraint = triplet <cible, condition, effet>
    
    Exemple de contrainte: 
    S1 & (S2 | S3) => S5 & !S6  (condition => effet)
        - S1 & (S2 | S3) : Indique des modules sélectionnés
        - S5 & !S6 : Indique les conséquences. 
                => S5 pour signifier que le module S5 doit être pris, 
                => !S6 pour signifier que le module ne peut pas être pris.

    Syntaxe enrichie :
        E(<Sigle>)
        Le module <Sigle> est vivement encouragé 
        ex : S1 & (S2 | S3) => E(S5)

        C(<Sigle>)
        Le choix du module <Sigle> nécessite l’approbation de la commission 
        ex : S1 & (S2 | S3) => C(S5)

        T(<Sigle>)
        Le choix du module <Sigle> nécessite la réussite d’un test
        ex : S1 & (S2 | S3) => T(S5)

        M[<Sigle1> > <Sigle2>]
        Le module <Sigle1> est remplacé par le module <Sigle2>
        ex : S1 & (S2 | S3) => M[S4 > S5]

=end

    @@spec_symbols = ["[","]",">"]
    @@spec_effects = ["E","C","T","M"]

    def initialize(target)
        super(target)
    end

    def check_all()
        if !check_contrainte_target then return false end
        if !check_condition then return false end
        if !check_effet then return false end
        return true
    end

    # Renvoie true si le format de la cible, et le sigles mentionné, sont correctes 
    def check_contrainte_target()
        res = unknown_sigles_list([@target.target])
        if(!res.empty? && @target.target!="*")
            @report.write("La cible fait référence à un sigle qui n'est repris dans la base de donnée et qui est différent de '*': " + res[0] , $choice_category)
            return false
        elsif(!check_sigles_version(@target.target))
            @report.write("La cible fait référence à un sigle qui ne correspond pas a une version actuelle", $choice_category)
            return false
        end         
        return true
    end

    # Renvoie true si le format de la condition, et les sigles qui y sont mentionnés, sont correctes 
    def check_condition()
        expr = LogicalExpression.new(@target.cond)
        if(!expr.well_formed?())
            @report.write("La condition n'est pas syntaxiquement correcte. Connecteurs reconnus : " + LogicalExpression.symbols() * ", " , $choice_category)
            return false
        elsif(!(res = unknown_sigles_list(expr.extract_variables())).empty?)
            @report.write("La condition fait référence à des sigles qui ne sont pas repris dans la base de donnée : " + res * ", " , $choice_category)
            return false    
        elsif(!check_sigles_version(expr.extract_variables()))
            @report.write("La condition fait référence à un sigle qui ne correspond pas a une version actuelle", $choice_category)
            return false
        end     
        return true
    end

    # Renvoie true si le format de l'effet, et les sigles qui y sont mentionnés, sont correctes,
    # et que, si une substitution est impliquée, qu'elle est effectivement faisable vis à vis
    # des données de la base de données et des autres contraintes.
    def check_effet()

        # "ou" et "xor" n'ont pas de sens pour les effets
        if(@target.effet.include?("|") || @target.effet.include?("^"))
            @report.write("L'effet n'est pas syntaxiquement correcte, les 'or' et 'xor' ne sont pas autorisés pour ce champ. ", $choice_category)
            return false
        end

        # Vérification que les symbôles "[" et ">" correspondent au nombre de "M".
        effet = " " + @target.effet
        if(!by_pairs?(effet, " M [", ">") || !by_pairs?(effet, " M [", "[") || !by_pairs?(effet, " M [", "]"))
            @report.write("L'effet n'est pas syntaxiquement correcte.", $choice_category)
            return false
        end

        # Adaptation des effets pour obtenir une version syntaxiquement équivalente, sans le vocabulaire enrichi
        # Le vocabulaire enrichi n'est pas reconne par LogicalExpression
        a_effect = adapted_effect()
        expr = LogicalExpression.new(a_effect)
        
        if(!expr.well_formed?())
            @report.write("L'effet n'est pas syntaxiquement correcte. ", $choice_category)
            return false
        elsif(!(res = unknown_sigles_list(expr.extract_variables())).empty?)
            @report.write("L'effet fait référence à des sigles qui ne sont pas repris dans la base de donnée : " + res * ", " , $choice_category)
            return false
        elsif(!check_sigles_version(expr.extract_variables()))
            @report.write("L'effet fait référence à un sigle qui ne correspond pas a une version actuelle", $choice_category)
            return false
        end     

        sigles = extract_sigles()
        effects = [true, false].concat(@@spec_effects)
        hash_effect = extract_effects()

        # Vérification que chaque paire sigle - effet obtenue depuis le champ effet,
        # A bien du sens.
        hash_effect.each_pair do |k, v|
            if(sigles.index(k) == nil || (effects.index(v)==nil && sigles.index(v)==nil)) 
                @report.write("L'effet n'est pas syntaxiquement correcte. ", $choice_category)
                return false
            end
            if(sigles.include?(k) && sigles.include?(v)) # Cas d'une substitution
                if(!valid_substitution?(k, v, @report))
                    return false
                end
            end 
        end

        return true

    end

    # Renvoie true si le la condition est vérifiée par le contexte.
    def triggered?(context)
        if(@target.target == "*" || context.include?(@target.target))
            expr = LogicalExpression.new(@target.cond)
            return expr.evaluate(context)
        else
            return false 
        end
    end

    # Renvoie un dictionnaire pour lequel chaque paire a la forme suivante : <sigle, effet correspondant>
    # Les effets existants sont !, E, T, C et <sigle2>. Si un autre sigle est dans la partie "effet"
    # c'est que l'effet est une substitution de <sigle> par <sigle2>
    def extract_effects()
    
        res = {}
        tmp = split_str(@target.effet, ["(",")","&",">","[","]",], " ")
        sigles = extract_sigles()
        
        # Parcours de chaque éléments du champ effet, et ajout des paires dans le résultat
        i = 0
        while(i<tmp.size())
            if(tmp[i] == "M")
                res[tmp[i+1]] = tmp[i+2]
                i += 3
            elsif(sigles.index(tmp[i])!=nil)
                res[tmp[i]] = true
                i += 1
            elsif(tmp[i] == "!")
                res[tmp[i+1]] = false
                i += 2
            else
                res[tmp[i+1]] = tmp[i]
                i += 2
            end
        end
        
        return res
    end

    # Renvoie une liste de l'ensemble des sigles mentionnés dans la contrainte
    def extract_sigles()        
        expr = LogicalExpression.new(@target.cond)

        # Ajout des sigles de la condition
        result = expr.extract_variables()           

        # Ajout des sigles de l'effet
        es = target_sigles()
        result.concat(es)

        # Ajout de la cible
        if(@target.target != "*")
            result << @target.target
        end

        return result.uniq
    end

    def self.spec_symbols()
        res = []
        @@spec_symbols.each do |s|
            res << s
        end
        return res
    end

private

    # Renvoie true si sigles est un tableau contenant que des sigles de version actuelles
    def check_sigles_version(sigles)
        if sigles == nil then return false end
        if !sigles.kind_of?(Array) then sigles = [sigles] end
        sigles.each do |s|
            if(! VersionManager.is_main_version?(s) )
                return false
            end
        end
        return true
    end

    # Renvoie la liste des sigles mentionnés dans l'effet.
    # Le fait qu'une chaine de caractères est un sigle dépend du 
    # contexte dans l'effet (Ex : E(T) => T est un sigle, T(S) => T n'est pas un sigle).
    def target_sigles()

         # Suppression de symbôles liés aux effets
        res = " " + @target.effet
        @@spec_effects.each do |s|
            if(s == "M")
                res = res.gsub(" " + s + " ["," ")
            else
                res = res.gsub(" " + s + " ("," ")
            end
        end
        
        LogicalExpression.symbols().each do |s|
            res = res.gsub(s," ")
        end
         
        # Suppression de tous les autres symboles n'appartenant pas aux sigles 
        # parenthèses fermantes, etc
        @@spec_symbols.each do |s|
            res = res.gsub(s," ")
        end
        res = res.split(" ")

        return res

    end

    # Renvoie true si la substitution du module de sigle "init_sigle" 
    # par celui de sigle "new_sigle" est réalisable
    def valid_substitution?(init_sigle, new_sigle, report)
        init_id = PmoduleObject.id?(init_sigle)
        new_id = PmoduleObject.id?(new_sigle)
        if(init_id == nil || new_id == nil)
            return false
        end

        r = true 

        # Applique les changemnts
        res, id_list, parent_list = do_changes(init_id, new_id)
        
        if(!res)
            @report.write("Substitution impossible, la base de donnée ne permet pas d'avoir deux contenus exactement identiques", $choice_category)
            r = false
        else
            # Check des contraintes sur chaque parent
            parent_list.each do |pid|   
                if(Pmodule.find(pid).mtype == "cours")
                    m = CoursObject.new()
                else
                    m = EnsembleObject.new()
                end
                m.load(pid)

                dscc = DbStructuralConstraintsChecker.new(m)
                r &= dscc.check_all()
            end
        end

        # Défait les changements 
        # (même si modifications interrompues, il fait remettre les données à leur état initial)
        undo_changes(id_list, init_id)      

        if(!r)
            @report.write("Substitution impossible, la structure induite par la substitution est invalide. ", $choice_category)
        end

        return r
    end

    # Substitue dans la base de donnée tout contenu init_id par new_id
    # Renvoie une liste des identifiants de "EnsembleContenu" qui ont été modifiée (id_list)
    # ainsi que la liste des identifiant des module qui ont vu leur contenu modifier (parentlist)
    def do_changes(init_id, new_id)
        id_list = []
        parent_list = []
        begin # Modification peut entrainer une erreur SQL
            EnsembleContenu.find_all_by_contenu_id(init_id).each do |ec|    
                ec.contenu_id = new_id
                ec.save
                parent_list << ec.pmodule_id
                id_list << ec.id
            end
        rescue
            # Si modufication, renvoie false, mais aussi les listes
            # de ce qui a été modifié jusque là
            return false, id_list, parent_list
        end
        return true, id_list, parent_list
    end

    # Pour chaque EnsembleContenu dont l'identifiant est contenu dans id_list
    # remplace l'id contenu par init_id
    def undo_changes(id_list, init_id)
        id_list.each do |id|                                                
            ec = EnsembleContenu.find(id)
            ec.contenu_id = init_id
            ec.save
        end
    end

    # Depuis une liste de sigles, renvoie ceux paris celle-ci qui ne sont pas présents 
    # dans la base de donné
    def unknown_sigles_list(sigles)
        res = []
        sigles.each do |s|
            if Sigle.find_by_sigle(s) == nil
                res << s
            end
        end
        return res
    end

    # Renvoie une version adaptée de l'effet ou la syntaxe enrichie est supprimée
    # Ex : E(A) & M[B > C] donnera A & B & C 
    def adapted_effect()
        a_effect = " " + @target.effet.to_s
        
        a_effect = a_effect.gsub(" E ("," (") # E(Sigle) devient (Sigle)
        a_effect = a_effect.gsub(" C ("," (") # C(Sigle) devient (Sigle)
        a_effect = a_effect.gsub(" T ("," (") # T(Sigle) devient (Sigle)

        a_effect = a_effect.gsub(" M ["," [")   # M[S4 > S5] devient [S4 > S5]
        a_effect = a_effect.gsub(">","&")       # [S4 > S5] devient [S4 & S5]
        a_effect = a_effect.gsub("[","").gsub("]","") # [S4 > S5] devient (S4 & S5)

        return a_effect
    end

    # Renvoie true si le nombre d'occurence de e1 et e2 dans "string" est le même
    def by_pairs?(string, e1, e2)
        if(string == nil || e1 == nil || e2 == nil)
            return false
        elsif(string.scan(e1).length == string.scan(e2).length)
            return true
        else
            return false
        end
    end

    # Renvoie un tableau contenant str décomposés selon la chaine "séparator"
    # dans lequel les symbôles présents dans l'ignore_list sont ignorés.
    # Ex : split_str("a b c d", ["a", "e"], " ") donnera ["b","c","d"]
    def split_str(str, ignore_list, separator)

        tmp = str
        ignore_list.each do |i|
            tmp = tmp.gsub(i,separator)
        end
        
        return tmp.split(separator)
    end

end
