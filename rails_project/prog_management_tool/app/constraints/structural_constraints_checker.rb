# encoding: utf-8

class StructuralConstraintsChecker < ConstraintsChecker

	$structural_category = "Contraintes sur la structure"
	
	def check_all()
		if !check_all_except_parent then return false end
		if !check_credits_parent then return false end
		return true
	end

	def check_all_except_parent()
		if !check_loops then return false end
		if !check_credits_children then return false end
		if !check_strict_credits_on_instance then return false end
		return true
	end

	# Renvoie false si les crédits des enfants de target sont tels qu'il est impossible de 
	# valider l'ensemble target. Renvoie true sinon, ou si la cible est un cours. 
	def check_credits_children()
		raise 'Try to use an abstract method'
	end

	# Effectue check_credits_children sur les parents existants de target. (Une descritpion plus précise
	# est donnée dans les sous-classes implémentant la méthode)
	def check_credits_parent()
		raise 'Try to use an abstract method'
	end

	# Vérifier que l'ajout du module de créerait pas de cycles
	# Vérifier que le module, idem pour son contenu (récursivement),
	# ne peut jamais atteindre un module du même sigle par récursion sur les
	# contenus. Renvoie true si aucun cycle n'est trouvé, false sinon.
	def check_loops()
		raise 'Try to use an abstract method'
	end

	# Vérifie que la cible, si ses créditsMin et créditsMax sont égaux, permet
	# une sélection d'exactement les crédits nécessaire parmi son contenu.
	# Renvoie true si la condition est vérifiée, ou si le module est un cours, false sinon.
	def check_strict_credits_on_instance()
		raise 'Try to use an abstract method'
	end

	# Vérifie que mod permet une sélection d'exactement "value" crédits.
	# Renvoie true si oui, false sinon. (Plus générique que check_strict_credits_on_instance)
	def self.check_strict_credits(mod, value)
		raise 'Try to use an abstract method'
	end

private

	# Depuis un module et une liste de modules supposées être son contenu,
	# vérifie les contraitnes existantes sur les enfants.
	def check_credits_children_glob(mod, children_modules)
		if(children_modules.empty?)
			return true
		end
		
		# Calcul de la somme sur les bornes min max des modules contenu
		r, sum_o_min, sum_max = credits_sums(mod, children_modules)

		if(!r)
			return false
		end

		return check_credits(mod, sum_o_min, sum_max)
	end

	# Renvoie la somme des crédits minimum des modules contenus obligatoires
	# ainsi que la somme des crédits maximum de tous les modules contenus.
	def credits_sums(mod, children_modules)
		
		if(!mod.kind_of?(EnsembleObject) || !children_modules.kind_of?(Array))
			return false, :args_type_error, nil
		end

		content_array = mod.get_content_array()

		if(content_array.size != children_modules.size)
			return false, :args_size_error, nil
		end

        content_array.each do |s, a, o|
        	if(find_mod(children_modules,s) == nil)
        		return false, :args_match_error, nil
        	end
        end

		sum_o_min = 0	# Somme des credits minimum pour le contenu obligatoire
        sum_max = 0		# Somme des crédits maximum pour tout le contenu

        content_array.each do |s, a, o|
        	if(o == true) # o = "obligatoire"
				sum_o_min += find_mod(children_modules, s).creditsMin
			end
			sum_max += find_mod(children_modules, s).creditsMax
		end		

		return true, sum_o_min, sum_max
	end

	# Rertrouve un module depuis un sigle dans un tableau de modules.
	def find_mod(mod_array, sigle)
		mod_array.each do |m|
			if(m.sigles_array().index(sigle)!=nil)
					return m
			end
		end
		return nil
	end

	# Compare les crédits du module mod avec les bornes 
	# - sum_o_min : somme des credits minimum pour le contenu obligatoire de mod
	# - sum_o_max : somme des crédits maximum pour tout le contenu de mod
	# Remplis le rapport en conséquence
	def check_credits(mod, sum_o_min, sum_max)
		creditsMin = mod.creditsMin.to_i
		creditsMax = mod.creditsMax.to_i

		res = true
        if(creditsMin > sum_max)
        	@report.write("La valeur des crédits minimum d'un ensemble doit être plus petite ou égale à la somme des crédits maximum de ses modules contenus ("+sum_max.to_s+")", $structural_category)
        	res = false
        end

        if(creditsMax < sum_o_min)
        	@report.write("La valeur des crédits maximum d’un ensemble doit être supérieure ou égale à la somme des crédits minimum de ses modules contenus obligatoires ("+sum_o_min.to_s+")", $structural_category)
        	res = false
        end

        if(creditsMin < sum_o_min)
        	@report.write("La valeur des crédits minimum d’un ensemble doit être supérieure ou égale à la somme des crédits minimum de ses modules contenus obligatoires ("+sum_o_min.to_s+")", $structural_category)
        	res = false
        end
	
		return res	
	end

	# Renvoie true si les sigles appartiennent au même module, false sinon.
	def same_module?(sigle1, sigle2)
		if sigle1 == sigle2 then return true end
		
		s1 = Sigle.find_by_sigle(sigle1)
		s2 = Sigle.find_by_sigle(sigle2)
		if(s1==nil || s2==nil) # Cas ou les sigles appartiennent à de nouveaux modules uniquement
			return false
		end

		if(s1.pmodule_id == s2.pmodule_id)
			return true
		else
			return false
		end
	end	

	# Renvoie true si "list", liste de sigles, contient un sigle correspondant au module
	# de sigle "sigle", sachant qu'un module peut avoir plusieurs sigles.
	# Renvoie false sinon.
	def contains_sigle?(sigle, list)
		list.each do |s|
			if(same_module?(sigle, s))
				return true
			end
		end
		return false
	end	

	# Renvoie false, ainsi que le chemin correspondant au cycle,
	# si un sigle du module current est contenu dans path, le chemin exploré
	# jusque là, sinon, s'invoque récursivement sur le contenu en mettant le path à jour.
	# Une fois tout le contenu exploré, renvoie true (aucun cycle n'existe).
	def recursive_check_loops(current, path)
		# Si le chemin contient déjà un sigle de current, un cycle existe.
		if(contains_sigle?(current, path))
			path << current
			# Renvoie la portion du chemin contenant le cycle
			return false, path[path.index(current)..path.size-1]
		else
			# Sinon, récupère le contenu de current
			contents_sigles = get_content_sigles(current)
			if(contents_sigles == nil)
				# Feuille atteinte
				return true, nil
			else
				# Met a jour le path
				path << current
				
				# Effectue un appel récursif sur chaque module contenu
				contents_sigles.each do |s|
					res, trace = recursive_check_loops(s, path)
					if(!res)
						return false, trace
					end
				end
				path.delete(current)
			end
		end
		return true
	end

	# Méthode utilisée par recursive_check_loops devant être implémentée dans les
	# sous classes. Renvoie la liste des sigles des modules contenus dans le module de sigle "sigle".
	def get_content_sigles(sigle)
		raise 'Try to use an abstract method'
	end
	
	# Renvoie la liste des entiers compris entre min et max
	def self.list_values(min, max)
		if min == nil || max == nil || min > max then return nil end
		res = []
		(min..max).each do |i|
			res << i
		end
		return res
	end

	# Renvoie toutes les combinaisons entre deux vecteurs
	# Exemple : [a1,a2] X [b1,b2] donnera [[a1,b1],[a1,b2],[a2,b1],[a2,b2]]
	def self.product(arr1, arr2)
		if arr1 == nil || arr2 == nil then return nil end
		result = []
		arr1.each do |v1|
			arr2.each do |v2|
				result << [v1, v2]
			end
		end
		return result
	end

	# Depuis une liste de vecteurs, renvoie une autre liste
	# contenant ceux dont la somme vaut "value"
	def self.filter_on_sum(list, value)
		if list == nil || value == nil then return nil end
		result = []
		list.each do |sub_arr|
			if !sub_arr.kind_of?(Array) then return nil end
			if(sub_arr.inject(:+) == value.to_i)
				result << sub_arr
			end
		end
		return result
	end

=begin
	
	Cette méthode a pour but de lister toutes les combinaisons de n nombres en fonction d'une
	liste décrivant les valeurs min et max de ceux-ci, ainsi qu'un booléen indiquant si le nombre
	peut être mis à zéro ou pas (true = ne peut pas valoir zéro).

	Ex : pour 
			min_max_list = [[1,2,false],[3,4,true]]
	  	 il existe 6 combinaisons
	  	 	[1,3],[1,4],[2,3],[2,4],[0,3],[0,4]

=end
	def self.all_combinations_aux(min_max_list)
		if min_max_list == nil || min_max_list.empty? then return nil end
	
		result = []

		# Pour chaque élément
		min_max_list.each do |min, max, v|
			# Liste les valeurs possibles
			arr = list_values(min,max)
			if !v then arr << 0 end 
			if(result.empty?)
				arr.each do |a|
					result << [a]
				end
			else
				# Combine ces valeurs avec les valeurs possibles trouvées aux itérations précédentes
				result = product(result, arr)
			end
		end

		result.each do |tmp|
			if(tmp.kind_of?(Array))
				tmp.flatten!()
			end
		end

		return result
	end

=begin

	Soit n modules, placés dans une liste composée de pairs <module, booléen> ou chaque booléen
	indique si le module correspondant est obligatoire ou non,

	La méthode renvoie une liste de toutes les combinaisons de crédits sélectionables pour ces
	modules.

	Par exemple, si la liste contient un cours valant 5 crédits obligatoire, et un
	ensemble valant entre 4 et 5 crédits, non obligatoire, le résultat sera les combinaisons

	[5,4],[5,5] et [5,0]

	La première valeur reste toujours a 5 puisque le cours vaut 5 crédits et sera toujours sélectionné,
	Tandis que la seconde peut valoir 4, 5 ou 0 crédits (0 car non obligatoire donc peut ne pas être sélectionné) 

=end
	def self.all_combinations(contenu_arr)
		
		if contenu_arr == nil then return nil end
		if contenu_arr.empty? then return [] end

		min_max_list = []
		contenu_arr.each do |mod, o|
			min_max_list << [mod.creditsMin, mod.creditsMax, o]
		end
		poss = all_combinations_aux(min_max_list)
		return poss
	end

end