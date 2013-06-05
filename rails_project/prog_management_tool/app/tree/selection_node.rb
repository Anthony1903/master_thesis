class SelectionNode < Node

    def initialize(data, selected = false)
        super(data)
        @selected = selected
    end

    def select
        @selected = true
    end

    def deselect
        @selected = false
    end

    def is_selected?
        return @selected
    end

    # Renvoie une liste des noeuds contenus et sélectionnés, 
    # contennant le noeud lui lui-même si il est sélectionné, 
    # dans l'ordre des enfants vers les parents.
    def list_selected_nodes()
        res = []
        @children.each do |c|
            if(c.is_selected?)
                res.concat(c.list_selected_nodes)
            end
        end
        if(is_selected?)
            res << self
        end
        return res
    end

    # Renvoie un clone de l'arborescence dont la racine est le noeud. Chaque noeud du résultat
    # est un clone correspondant à un noeud de l'arborescence. 
    # Les données ne sont pas clonées.
    def clone()
        res = SelectionNode.new(@data)
        if(is_selected?)
            res.select
        end
        @children.each do |c|
            res.add_child(c.clone())
        end
        return res
    end

end