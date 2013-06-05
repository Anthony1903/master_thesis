class TreeFieldConstraintsChecker < FieldConstraintsChecker
    
=begin
        
    Voire FieldConstraintsChecker pour plus d'explications

=end

    # target est un noeud contenant un module, et root la racine d'un arbre contenant target
    def initialize(target, root)
        super(target)
        @root = root
    end

    def check_fields()
        return check_fields_glob(@target.data)
    end

    def check_content_existence()
        if(@target.data.mtype == "cours")
            return true
        end

        # Pour chaque élément faisant partie du contenu du module
        @target.data.get_content_array.each do |s, a, o|
            found = false

            # Vérifie qu'un noeud enfant contient l'élément
            @target.children.each do |c|
                if(c.data.sigles_array().include?(s))
                    found = true
                end
            end
            if(!found) 
                @report.write("#{s} ne fait pas partie des noeuds enfants alors qu'il compose le contenu du module #{@target.data.sigles_array()[0]}" , $field_category)
                return false 
            end
        end
        return true
    end

    def check_content_duplications()
        return check_content_duplications_glob(@target.data)
    end

    # Renvie un id unique pour le module de sigle "sigle"
    def get_uid(sigle)
        @target.children.each do |n|
            if(n.data.sigles_array().index(sigle)!=nil)
                return n.data.sigles_array().sort.to_s
            end
        end
        return nil
    end

end