# encoding: utf-8

class SelectionTree < Tree

=begin

	Construit l'arbre complet de racine "root" depuis les informations données par les modules contenus 
	dans les noeuds, ainsi que les données de la DB.
	Le résultat est un arbre de SelectionNode dont les noeud sont selectionnés 
	si leur contenu est obligatoire pour le parent ainsi que tout les ancêtres.

	Arguments :
	- first : indique que l'appel à la méthode est le premier, il faut donc sélectionner la racine 
	- mandatory : indique si le noeud est obligatoire compte tenu du parent et de tous les ancêtres
	- root : un SelectionNode

=end	
	def self.build_tree(root, mandatory = true, first = true)

		# Si racine de l'arbe, sélectionne le noeud
		if(first) then root.select end

		# Si le noeud contient un cours, arrêt 
		if(root.data.mtype == "cours") then return end

		# Si le noeud contient un ensemble, parcours le contenu
		ac = root.data.get_content_array()
		ac.each do |s, a, o|

			# Crée un noeud
			selection_node = create_selection_node(s)
			
			# Le sélectionne si nécessaire
			mandatory_tmp = o & mandatory
			if mandatory_tmp then selection_node.select() end

			# L'ajoute au noeud parent
			root.add_child(selection_node)

			# Construit le sous arbre correspondant au noeud
			build_tree(selection_node, mandatory_tmp, false)
		end

	end
	
private

	# Depuis un sigle, renvoie un SelectionNode contenant le module associé au sigle
	def self.create_selection_node(s)
		id = PmoduleObject.id?(s)
		if(Pmodule.find(id).mtype == "cours")
			m = CoursObject.new()
		else
			m = EnsembleObject.new()
		end
		m.load(id)
		return SelectionNode.new(m)
	end

end