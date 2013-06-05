class Tree

	# Construit l'arbre complet de racine "root" depuis les informations données par les modules contenus 
	# dans les noeuds, ainsi que les données de la DB.
	def self.build_tree(root)
		if(root.data.mtype == "cours") then return end
		ac = root.data.get_content_array()
		ac.each do |s, a, o|
			node = create_node(s)
			root.add_child(node)
			build_tree(node)
		end
	end

	# Renvoie toutes les paires [parent, noeud] tel que "noeud" contient le module de sigle "sigle".
	# Si le noeud est la racine, le parent est mis à nil dans la paire.
	# (Toute paire devrait être unique car un même module ne devrait pas pouvoir contenir deux fois le même module)
	def self.find_nodes(root, sigle, parent = nil)
		result = []
		if root == nil || sigle == nil then return :error end

		# Si le noeud "root" est le noeud recherché, inclus la paire dans le résultat
		if(root.data.sigles_array.include?(sigle))
			result << [parent, root]
		else

			# Recherche récursive sur les contenus
			root.children.each do |c|
				r = find_nodes(c, sigle, root)
				if(r!=nil && r!=:error)
					result.concat(r)
				end
			end

		end
		return result
	end

	# Renvoie le premier noeud qui contient le module de sigle "sigle".
	# Idem que find_nodes, mais s'arrête au premier noeud trouvé.
	def self.find_node(root, sigle)
		if root == nil || sigle == nil || sigle.gsub(" ","") == "" then return :error end
		if(root.data.sigles_array.index(sigle) != nil)
			return root
		else
			root.children.each do |c|
				r = find_node(c, sigle)
				if(r!=nil && r!=:error)
					return r
				end
			end
		end
		return :error
	end

	# Supprime le noeud qui contient le module de sigle "sigle", et dont le parent contient 
	# le module de sigle "parent", de l'arborescence de racine "root". 
	# Le contenu du module parent est adapté pour ne plus mentionner le module
	def self.remove_node(parent, sigle, root)

		if parent == nil || sigle == nil then return :error end

		# Récupérations de tous les noeuds correspondant au sigle
		p_n_pairs = find_nodes(root, sigle)
		if(p_n_pairs != :error && !p_n_pairs.empty?)

			# Parcours de toutes les paires parent - noeud
			p_n_pairs.each do |p, n|

				# Si le parent correspond
				if(p.data.sigles_array.include?(parent))
					
					# Adapte le contenu
					c = p.data.get_content_array
					new_c = []
					c.each do |s, a, o|
						if(s != sigle)
							new_c << [s, a ,o]
						end
					end
					p.data.set_content_array(new_c)

					# supprime le noeud
		        	remove_child_by_sigle(p, sigle)

					return true
				end
			end
		end
			
		return false

	end	

	# Supprime le noeud contenant le module de sigle "sigle" des enfants de "node".
	def self.remove_child_by_sigle(node, sigle)
		new_children = []
		mod = false
		node.children.each do |c|
			if(c.data.sigles_array.index(sigle)==nil)
				new_children << c
			else
				mod = true
			end
		end
		node.children = new_children
		return mod
	end

private

	# Depuis un sigle, renvoie un Node contenant le module associé au sigle
	def self.create_node(s)
		id = PmoduleObject.id?(s)
		if(Pmodule.find(id).mtype == "cours")
			m = CoursObject.new()
		else
			m = EnsembleObject.new()
		end
		m.load(id)
		return Node.new(m)
	end

end