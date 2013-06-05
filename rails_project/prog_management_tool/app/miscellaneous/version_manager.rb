class VersionManager

	# Tente de sauvegarder le module correspondant à params
	def self.save(params, report)
		params = params_according_to_validity(params)
		new_mod = create_module(params)
		return try_saving_module(report, new_mod)
	end

	# Tente de mettre à jour le module correspondant à id
	# dans la DB avec les paramètres params 
	def self.update(id, params, report, archive = true)	
		params = params_according_to_validity(params)	
		mod = create_module(params)
		mod.load(id)
		return try_updating_module(report, mod, params, archive)
	end

	# Renvoie true si "sigle" correspond à une version actuelle 
	def self.is_main_version?(sigle)
		if(sigle == nil || sigle.gsub(" ","")=="")
			return false
		else
			return !has_suffix?(sigle)
		end
	end

	# Renvoie true si "sigle" correspond à une version archive 
	def self.is_archive_version?(sigle)
		if(sigle == nil || sigle.gsub(" ","")=="" || !has_suffix?(sigle))
			return false
		else
			tmp = sigle.split("_(")
			return tmp[1].size > 5 
		end
	end

	# Archive le module correspondant à "sigle". Si le module est un ensemble,
	# archive son contenu récursivement
	def self.archive(sigle)

		# Archive par rapport à la date actuelle
		t = Time.now.to_s

		# Vérifie que la version est une version actuelle
		if(VersionManager.is_main_version?(sigle))

			# Récupère le module
			s = Sigle.find_by_sigle(sigle)
			if s==nil then return false end

			if(Pmodule.find(s.pmodule_id).mtype == "cours")
				m = CoursObject.new()
			else
				m = EnsembleObject.new()
			end
			m.load(s.pmodule_id)

			# Archive récursivement
			r = recursive_archive(m, t)
		
		else
			return false
		end
	end


	# Renvoie une instance de type correspondant au champ "mtype" de "params",
	# et contenant les données de "params".
	def self.create_module(params)
		if params == nil then return nil end
		if(params[:mtype] == "cours")
			return CoursObject.new(params)
		elsif(params[:mtype] == "ensemble")
			return EnsembleObject.new(params)
		else
			return nil
		end
	end

	# Renvoie la version des paramètres du module mod, correspondant à la date 
	# de validité et la date actuelle
	def self.params_according_to_validity(params)
		mod = create_module(params)
		if(in_future?(mod.validite))
			return future_version_params(mod)
		else
			return actuel_version_params(mod)
		end
	end


	# Renvoie true si la valeur du champ "validite" du module mod correspond à une version future.
	# Hypothèse que la date séparant les années correspond au 1er septembre
	def self.in_future?(val)
		v = val.to_i
		validite = Date.new(v,9,1)
		return Date.parse(validite.to_s) > Date.today
	end

private

	# Archive récursivement mod, ainsi que son contenu si mod est un
	# ensemble
	def self.recursive_archive(mod, time = nil)
		res = true
		if time == nil then time = Time.now.to_s end
		
		# Sauvegarde de la version archive du contenu de mod si nécessaire
		if(mod.mtype == "ensemble")
			mod.get_content_array.each do |s, a, o|
				child_id = Sigle.find_by_sigle(s).pmodule_id
				if(Pmodule.find(child_id).mtype == "cours")
					child_mod = CoursObject.new()
				else
					child_mod = EnsembleObject.new()
				end
				child_mod.load(child_id)
				res &= recursive_archive(child_mod, time)
			end
		end

		# Sauvegarde de la version archive de mod 
		archive_version = archive_version_params(mod, time)
		if(mod.mtype == "cours")
			old = CoursObject.new(archive_version)
		else
			old = EnsembleObject.new(archive_version)
		end
		id = old.save()
		res &= (id > 0)
		
		return res
	end

	# Tente de sauvegarder un module mod. Complète le rapport selon le résultat
	def self.try_saving_module(report, mod)
	   	id = mod.save
	    if id < 0
			mod.get_report.list.each do |m|
	    		report.write(m,"strict error")
	    	end
	    	return false
	    else
	    	return true
	    end
	end


	# Met à jour le module chargé mod (le champ id doit obligatoirement contenir l'id 
	# du module dans la DB) avec les paramètres params. 
 	# Si archive est a true, archive la version actuelle récursivement.
	def self.try_updating_module(report, mod, params, archive)

		old_version_params = mod.extract_params

		# Met à jour le module de la DB avec les params. /!\ Doit être une mise à jour pour que 
		# les liens dans la DB utilisant l'id de mod restent valables pour la nouvelle version.
		r = mod.update(params)

		# Archive si demandé et mise à jour réussie 
		if(r && archive)
			mod.update_params(old_version_params)
			t = Time.now.to_s
			recursive_archive(mod, t)
		end
		
		if(!r)
	    	mod.get_report.list.each do |m|
    			report.write(m,"strict error")
	    	end
	    	return false
	    else
	    	return true
	    end

	end

	# Renvoie le contenu passé en argument sous forme de chaine de caractères,
	# pour laquelle time a été concaténé à chaque sigle. 
	def self.adapt_content(content_array, time)
		if(content_array == nil)
			return ""
		end

		new_content = ""
		content_array.each do |s, a ,o|
			new_content += concat_time(remove_suffix(s), time)+ " " + a.to_s + " " + o.to_s + ", "
		end

		if(new_content.length > 2)
			new_content = new_content[0..new_content.length-3]
		end
		return new_content
	end
	
	# Renvoie le contenu passé en argument sous forme de chaine de caractères,
	# pour laquelle tout les suffixes de sigle sont retirés. 
	def self.remove_suffix_from_content(content_array)
		if(content_array == nil)
			return ""
		end

		new_content = ""
		content_array.each do |s, a ,o|
			new_content += remove_suffix(s).to_s + " " + a.to_s + " " + o.to_s + ", "
		end
		
		if(new_content.length > 2)
			new_content = new_content[0..new_content.length-3]
		end
		
		return new_content
	end

	# Renvoie la version des paramètres de mod correspondant
	# a une version archive (ne change pas la validité).
	def self.archive_version_params(mod, time = nil)
		archive_version = mod.extract_params()
		sigles = []
		archive_version[:sigles].each do |s|
			sigles << concat_time(s, time)
		end

		if(mod.mtype == "ensemble")
			new_content = adapt_content(mod.get_content_array, time)
			archive_version[:contenu] = new_content
		end

		archive_version[:sigles] = sigles
		archive_version[:status] = "archive"

		return archive_version
	end

	# Renvoie la version des paramètres de mod correspondant
	# a une version future (ne change pas la validité).
	def self.future_version_params(mod)
		future_version = mod.extract_params()
		sigles = []
		future_version[:sigles].each do |s|
			sigles << concat_validite(s, mod.validite)
		end
		future_version[:sigles] = sigles
		future_version[:status] = "future"

		if(mod.mtype == "ensemble")
			new_content = adapt_content(mod.get_content_array, mod.validite)
			future_version[:contenu] = new_content
		end

		return future_version
	end

	# Renvoie la version des paramètres de mod correspondant
	# a une version actuelle (ne change pas la validité).
	def self.actuel_version_params(mod)
		actuel_version = mod.extract_params()
		sigles = []
		actuel_version[:sigles].each do |s|
			sigles << remove_suffix(s)
		end
		actuel_version[:sigles] = sigles
		actuel_version[:status] = "actuel"

		if(mod.mtype == "ensemble")
			actuel_version[:contenu] = remove_suffix_from_content(mod.get_content_array())
		end

		return actuel_version
	end

	# Renvoie true si str contient un suffixe
	def self.has_suffix?(str)
		if(str==nil) then return false end
		return str.include?("_(") && str.include?(")")
	end

	# Supprime un éventuel suffixe de str
	def self.remove_suffix(str)
		if(has_suffix?(str))
			return str[0..str.index("_(")-1]
		else
			return str
		end
	end

	# Concatène time en fin de chaine "str". Si time est nil, concatène
	# la date (détaillée à la seconde près) actuelle à la place.
	def self.concat_time(str, time = nil)
		str = remove_suffix(str)
		if(time == nil)
			time = Time.now.to_s
		end
		r = (str.to_s + "_(" + time.to_s + ")")
		return r.gsub(" ", "_")
	end

	# Concatène la date de validité en fin de chaine "str"
	def self.concat_validite(str, validite)
		str = remove_suffix(str)
		return (str.to_s + "_(" + validite.to_s + ")")
	end

end