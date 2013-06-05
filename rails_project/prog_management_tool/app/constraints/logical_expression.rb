# encoding: utf-8

class LogicalExpression

    # Ensemble des symboles reconnus dans une expression, autre que les variables.
    @@symbols = ["&", "&&", "|", "||", "!", "^", "(", ")"]

    def initialize(expr)
        if expr != nil and expr.delete(" ") != ""
        
            @expr = expr

            # récupère les différentes variables de l'expression
            tokens = split(expr)
            
            # Etablis un mapping entre les variables initiales (aucune contrainte), et 
            # d'autres variables, celles utilisées pour l'évaluation (toutes en minuscules)
            @map = map(tokens)
            
            # Crée une chaine de caractère en prennant l'expression, et en remplacant
            # les variables selon le mapping obtenu.
            @formula = build_formula()
        
        else
            @formula = nil
        end
    end

=begin
    
    Evalue la formule selon le contexte passé en argument.
    Place toutes les valeurs de variables présentes dans le contexte à true
    les autres présentes dans l'expression à false. 
    Evalue ensuite la formule et renvoie le resultat (true ou false) 
    

    /!\ Attention : 
    L'expression est évaulée par Ruby, il faut faire en sorte d'éviter les conflits
    entre variables car l'environnement contextuel est prise en compte lors de l'évaluation
    du code. (utilisation du "_" en fin de chaque variable pour cette raison)  

=end    
    def evaluate(context)
        var_initialized = Hash.new(false)

        if context==nil || context=="" then context = [] end

        if(@formula==nil)
            return true
        else
            # Initialiser une variable qui contiendra le code à exécuter
            code_ = ""

            # Ajoute une ligne par variable devant être a true, séparées par ;
            context.each do |v_|
                var_ = @map[v_]
                if var_ != nil && !var_initialized[var_]
                    code_ += var_+" = true ; "
                    var_initialized[var_] = true
                end
            end

            # Ajoute une ligne par variable devant être à false, séparées par ;
            @map.keys.each do |t_|
                var_ = @map[t_]
                if var_ != nil && !var_initialized[var_]
                    code_ += var_+" = false ; "
                    var_initialized[var_] = true
                end
            end
            
            # Ajoute la formule après les assignations
            code_ = code_ + @formula

            # Utilise Ruby pour exécuter le code.
            begin
                res = eval(code_)
            rescue Exception => e
                res = :error
            end

            return res
            
        end
    end

    # Renvoie true si l'expression est bien formée, selon les règles des expressions logiques 
    def well_formed?()
        if(@expr == nil || @expr.gsub(" ","").gsub("(","").gsub(")","") == "" || @expr.count("(") != @expr.count(")"))
            return false
        else
            # Evalue l'expression sous un contexte vide, si une réponse est donnée, c'est que l'expression a un sens
            if(evaluate(nil) == :error) 
                return false
            else 
                return true
            end
        end
        return true
    end

    # Renvoie la liste des variables mentionnées dans l'expression 
    def extract_variables()
        if(@expr == nil || @expr.gsub(" ","") == "")
            return []
        end

        res = []
        arr = @expr.split(" ")
        arr.each do |s|
            tmp = s.gsub("(","").gsub(")","")
            if(tmp != "" && @@symbols.index(tmp) == nil)
                res << tmp
            end
        end
        return res.uniq
    end

    # Renvoie la liste @@symbols, reprennant l'ensemble des symboles reconnus, autre que les variables.
    def self.symbols()
        res = []
        @@symbols.each do |s|
            res << s
        end
        return res
    end

private

    # Reformule l'expression en substituant les variables de l'expression selon le mapping
    def build_formula()
        res = @expr
        keys = @map.keys

        # Ordre important !!!
        keys = keys.sort_by { |object| object.length }.reverse

        keys.each do |k|
            v = @map[k]
            res = res.gsub(k.to_s,v.to_s)
        end

        return res

    end

    # Renvoie le nom prochaine variable (a, b, c, ..., z, aa, ab, etc)
    def next_var(v)
        return v.next       
    end

    # Effectue un mapping "variables de l'expression" - "variables les représentant"
    def map(tokens)
        h = Hash.new()
        var = "a"
        tokens.each do |t|
            h[t] = var
            var = next_var(var)
        end
        return h
    end

    # Renvoie true si c représente un entier
    def is_num?(c)
        Integer(c)
        rescue ArgumentError
          return false
        else
          return true
    end

    # Renvoie true si c représente une lettre
    def is_letter?(c)
        if(c==nil || c == "") 
            return false
        else
            return (c[0]>=?a && c[0]<=?z) || (c[0]>=?A && c[0]<=?Z)
        end
    end

    # Renvoie la liste des variables contenues dans expr
    def split(expr)
        res = []
        tmp = ""
        expr.each_char do |e|
            if is_num?(e) || is_letter?(e) || e == '_'
                tmp += e
            else
                if tmp != "" 
                    res << tmp
                    tmp = ""
                end
            end
        end

        if is_num?(tmp) || is_letter?(tmp)
            res << tmp
        end
        
        return res.uniq
    end

end

