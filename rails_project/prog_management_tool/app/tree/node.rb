class Node

    attr_accessor :data, :children

    def initialize(data)
        @data = data
        @children = []
    end

    def add_child(child)
        @children << child
    end

    def remove_child(child)
        return @children.delete(child) != nil
    end

    def remove_children()
        @children = []      
    end

    # Renvoie une liste des données contenues dans les noeuds enfants, 
    # ainsi que celles du noeud lui-même, en partant des enfants et terminant par les parents
    def list()
        res = []
        @children.each do |c|
            res.concat(c.list)
        end
        res << @data
        return res
    end

    # Renvoie une liste des noeuds contenus, contenant le noeud lui-même, 
    # dans l'ordre des enfants vers les parents.
    def list_nodes()
        res = []
        @children.each do |c|
            res.concat(c.list_nodes)
        end
        res << self
        return res
    end

end