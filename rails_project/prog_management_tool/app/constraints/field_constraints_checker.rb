# encoding: utf-8

class FieldConstraintsChecker < ConstraintsChecker

	$field_category = "Contraintes sur champs"

	def check_all()
		if !check_fields then return false end
		if !check_content_existence then return false end
		if !check_content_duplications then return false end
		return true
	end

	# Renvoie true si les champs contenus dans target son valables, sinon false.
	def check_fields()
		raise 'Try to use an abstract method'		
	end

	# Renvoie true si le champ "contenu" fait référence à des sigles existants, ou si target est un cours, 
	# false sinon.
	def check_content_existence()
		raise 'Try to use an abstract method'
	end

	# Renvoie true si le champ "contenu" fait référence à des modules différents, ou si target est un cours,
	# false sinon.
	def check_content_duplications()
		raise 'Try to use an abstract method'
	end

private

	# Renvoie true si les champs contenus dans le présentateur mod
	# Sont correctes
	def check_fields_glob(mod)

		# Vérifie qu'un sigle est donné
		if(mod.sigles == nil || mod.sigles.gsub(" ","") == "")
			@report.write("Chaque module doit être associé à au moins un sigle", $field_category)
			return false
		end

		bck =  mod.sigles
		
		# Change le sigle du module temporairement, pour le test
		mod.sigles = mod.sigles_array[0] + "_TEMP"
		
		if(mod.mtype == "ensemble")
			cont = mod.contenu
			# Evite de checker les contraintes liées à l'existance du contenu
			mod.contenu = nil		
			# Tente une sauvegarde, vérfiant ainsi les champs par les mécanismes existant
			r = mod.save()			
			mod.contenu = cont
		else
			r = mod.save()
		end

		if(r >= 0)
			# Défait la sauvegarde si elle a réussi
			mod.destroy() 
			mod.sigles = bck
			return true
		else			
			mod.get_report().list.each do |m|
				@report.write(m, $field_category)
			end
			mod.erase_report()
			mod.sigles = bck
			return false
		end

	end

	# Renvoie true si le contenu de "mod" ne reprend pas deux fois le même module 
	# (deux éléments contenus faisant référence à deux sigles différents
	# peuvent faire référence deux fois au même module puisqu'un module peut avoir plusieurs sigles)
	def check_content_duplications_glob(mod)
		if mod.mtype == "cours" then return true end	
		hash = {}
		
		# Parcours du contenu
		mod.get_content_array.each do |s, a, o|
			
			# Récupère un identifiant étant unique pour le module de sigle "s"
			v = get_uid(s)
			
			# Vérifie son unicité
			if(hash[v] != true) 
				hash[v] = true
			else
				@report.write("Duplicaton dans les contenus ( " + s + ")", $field_category)
				return false
			end
		
		end

		return true
	end

end