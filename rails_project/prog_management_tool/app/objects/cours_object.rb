# encoding: utf-8

class CoursObject < PmoduleObject

	attr_accessor :dureeCours, :dureeTP, :quadri, :professeur

	def initialize(param = nil)

		if param == nil then param = {} end

		add_default_c(param)

		super(param)

		@dureeCours = param[:dureeCours]
		@dureeTP = param[:dureeTP]
		@quadri = param[:quadri]
		@professeur = param[:professeur]

		@mtype = "cours" # Initialise cette variable indépendament de l'input

	end

	# Renvoie un dictionnaire contenant la valeur de chaque variable d'instance
	def extract_params()
		param = extract_params_pm()
		param[:dureeCours] = @dureeCours
		param[:dureeTP] = @dureeTP
		param[:quadri] = @quadri
		param[:professeur] = @professeur
		return param
	end

	# Modification des variables d'instances
	def update_params(params)

		update_params_pm(params)
		
		if(params[:dureeCours] != nil)
			@dureeCours = params[:dureeCours]
		end

		if(params[:dureeTP] != nil)
			@dureeTP = params[:dureeTP]
		end
		
		if(params[:quadri] != nil)
			@quadri = params[:quadri]
		end
		
		if(params[:professeur] != nil)
			@professeur = params[:professeur]
		end
		
	end

	# Renvoie un dictionnaire de paires <:self, :other> reprennant
	# les différences entre les variables d'instances et les paramètres
	# passés en argument. Tout est comparé excepté le status.
	def compaire(other_params)
		param = extract_params()

		result = {}
		
		param.each_pair do |k, v|
			if(k!=:status)
				if(other_params[k] != v && other_params[k].to_s != v.to_s)
					result[k] = {:self => v, :other => other_params[k]}
				end
			end
		end

		if result=={} then return nil end
		
		return result
	end

    # Chargement du cours désignée par "id" (id du pmodule correspondant au cours)
    # dans le présentateur
	def load(id)

		if ((pm = load_pm(id))==nil) then return false end

		c = pm.cours_contenu
		if(c==nil) then return false end

		@dureeCours = c.dureeCours
		@dureeTP = c.dureeTP
		@quadri = c.quadri
		@professeur = c.professeur

		return true
	end

=begin

	Sauvegarde du cours dans le modèle, renvoie l'id du nouveau pmodule créé
	ou -1 si la sauvegarde a échoué.
	
	L'action échoue si les contraintes sur les cours ne sont pas respectées.
	Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
	def save()

		pm = nil

		if(!check_constraints(self))
			return -1
		end

		begin
		
			ActiveRecord::Base.transaction do

				pm = save_pm

				cc = pm.build_cours_contenu(
		            :dureeCours => @dureeCours,
		            :dureeTP => @dureeTP,
		            :quadri => @quadri,
		            :professeur => @professeur
					)
				@errors = cc.errors
				cc.save!

			end
		
		rescue => e
			return -1
		end

		@id = pm.id 

		return pm.id

	end

=begin
	
	Met à jour le cours dans le modèle depuis les paramètres donnés.
	
	Nécessite que @id contienne l'id du cours à modifier.
	
	Renvoie true si la mise à jour à réussi, false sinon.
	
	Si la mise à jour a réussi les variables d'instances sont adaptées
	sinon elles restent inchangées.
		
	L'action échoue si les contraintes sur les cours ne sont pas respectées.
	Lorsque l'action échoue, les raisons sont décrites dans l'objet @report

=end
	def update(params = {})

		if(@id==nil) then return false end

		bck = var_backup_c()

		add_default_c(params)

		@dureeCours = params[:dureeCours]
		@dureeTP = params[:dureeTP]
		@quadri = params[:quadri]
		@professeur = params[:professeur]

		tmp = CoursObject.new(params)
		if(!check_constraints(tmp))
			var_restore_c(bck)
			return false
		end

		begin
			
			ActiveRecord::Base.transaction do

				pm = update_pm(params)

				@errors = pm.cours_contenu.errors
				pm.cours_contenu.update_attributes!(
				            :dureeCours => params[:dureeCours],
				            :dureeTP => params[:dureeTP],
				            :quadri => params[:quadri],
				            :professeur => params[:professeur]
				           )
			end

		rescue => e
			var_restore_c(bck)
			return false
		end

		return true

	end

	# Renvoie la liste de tout cours existant dans le modèle,
	# chargés dans des CoursObject
	def self.load_all()
		ccs = CoursContenu.all()
		result = []
		ccs.each do |cc|
				co = CoursObject.new
				co.load(cc.pmodule_id)
				result << co 
		end
		return result
	end

	# Adapte le type des paramètres en fonction de ce qui est attendu par un CoursObject
	def self.adapt_types(params)
		if params == nil then return end
		if(params["dureeCours"].to_s.gsub(" ","") != "")
			params["dureeCours"] = params["dureeCours"].to_f
		end
		if(params["dureeTP"].to_s.gsub(" ","") != "")
			params["dureeTP"] = params["dureeTP"].to_f
		end
	end


private

	# Veille a ce les champs creditsMax et creditsMin
	# aient la même valeur lorsqu'une seule valeur est donnée
	def add_default_c(params)
		if params[:creditsMax] != nil
			params[:creditsMin] = params[:creditsMax]
		elsif params[:creditsMin] != nil
			params[:creditsMax] = params[:creditsMin]
		end
	end

	# Renvoie un dictionnaire contenant la valeur actuelles des variables d'instance 
	def var_backup_c()
		backup = extract_params()
		backup[:dureeCours] = @dureeCours
		backup[:dureeTP] = @dureeTP
		backup[:quadri] = @quadri
		backup[:professeur] = @professeur
		return backup
	end

	# Modifie les variables d'instance en fonction du dictionnaire "backup"
	def var_restore_c(backup)
		var_restore(backup)
		@dureeCours = backup[:dureeCours]
		@dureeTP = backup[:dureeTP]
		@quadri = backup[:quadri]
		@professeur = backup[:professeur]
	end

end