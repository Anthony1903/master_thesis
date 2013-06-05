# encoding: utf-8

require 'csv_hasher'

class CSVLoader

	attr_accessor :fnames, :state, :reports, :root_intit_abrege, :hashes

=begin

	Variables d'instance :

		@fnames : description des fichiers à utiliser pour l'import (dictionnaire de paires <nom, chemin>)
		@root_intit_abrege : dernière racine sélectionnée
		@stack : pile utilisée pour l'import. Détermine l'ordre qui devra être respecté pour importer 
				 un ensemble de modules depuis une racine particulière. Permet au loader de garder un état sur 
				 l'avancement de l'import.
		@stack_initial_size : taille qu'avait la pile actuelle après initialisation.
		@stack_current_size : taille actuelle de la pile

		@reports : ensemble des rapports qui n'étaient pas vide après le chargement d'un module. 
		     	   (dictionnaire de paires <sigle du module, rapport>)

		@cours_loader : instance de CoursLoader
		@ensemble_loader : instance de EnsembleLoader

		@state : état dans lequel le loader se trouve 
			 :waiting => en attente du prochain import, prêt.
			 :wait_feedback => en attente du feedback pour résoudre le blocage. 
			 				   (erreur rencontrée lors du dernier import)
			 :feedback_received => un feedback a été recu.

		@feedback : contient le dernier feedback recu.
		@last_answ : contient la dernière réponse envoyée par le loader, permet de la renvoyer, sans
					 la recalculer, lorsque load_next a été invoqué alors que le loader attend un feedback
					 qu'il n'a toujours pas recu.

=end

	# Initialise le loader en prennant une description de fichiers. Si aucune description n'est
	# donnée, charge des fichiers par défaut
	def initialize(fnames = nil)

		if(fnames == nil)
			@fnames = [{:name => "activites", :path => File.expand_path("db/EPCcsvs/activites.csv")}, 
					  {:name => "activites_root", :path => File.expand_path("db/EPCcsvs/activites_root.csv")}, 
					  {:name => "EPL_grp", :path => File.expand_path("db/EPCcsvs/EPL_grp.csv")}, 
					  {:name => "prof", :path => File.expand_path("db/EPCcsvs/prof.csv")}]
		else
			@fnames = fnames
		end

		@stack_initial_size = 0
		@state = :waiting

	end

	# Charge les fichiers et crée les loader nécessaires
	def load_files()
		h = CsvHasher.new(@fnames)

		r, data, fname = h.load

		if(!r)
			return false, data, fname
		end

		@hashes = data
		@cours_loader = CoursLoader.new(@hashes)
		@ensemble_loader = EnsembleLoader.new(@hashes)
		@reports = {}
		
		return true
	end

	# Renvoie la liste des racines présentes dans "activites_root"
	def roots_info()
		roots = []
		module_loader = ModuleLoader.new(@hashes)
		@hashes["activites_root"].each_value do |r|
			r = r[0]
			roots << r["RTRIM(INTIT_ABREGE)"]
		end
		return roots
	end

	# Renvoie true si les fichiers ont été chargé
	def files_loaded?()
		return @hashes != nil
	end

	# Renvoie la taille initiale de la pile, depuis la dernière réinitialisation 
	def stack_initial_size()
		return @stack_initial_size
	end

	# Renvoie la taille actuelle de la pile
	def stack_current_size()
		if(@stack == nil)
			return 0
		end
		return @stack.length
	end

	# Initialise la pile depuis une racine sélectionnée.
	def init_stack(root_intit_abrege)

		@root_intit_abrege = root_intit_abrege

		# Construit la pile et l'arbre correspondants
		r, tree_root = build_stack(root_intit_abrege)
		if(r)
			@stack_initial_size = @stack.length
			@state = :waiting
			@last_answ = nil
			@reports = {}
			# Génère l'image correspondante à l'arbre obtenu
			Graph.gen_graph(tree_root)
		end

		return r
	end

	# Réinitialise la pile actuelle, correspondant donc à la dernière racine
	# sélectionnée.
	def reinit_stack()
		return init_stack(@root_intit_abrege)
	end

=begin	

	Charge un module dans la base de donnée, et retourne true si le module a été sauvegardé, false sinon.
	"report" est un rapport qui contiendra un message par erreur, ainsi que warning ou avis de mise à jour, 
	rencontrés après l'exécution de la méthode.

	Deux cas de figures correspondant au deux phases de l'import d'un module :

	- (Phase 1) Soit l'identifiant désigne un module présent dans le dictionnaire obtenu depuis "activites", 
	  dans ce cas
	  	=> force = false
	  	=> extern_id contient l'identifiant du module dans le dictionnaire
	  	=> params sera remplis avec les données du dictionnaire le plus complètement possible, même en cas d'erreur.
	  
	- (Phase 2) Soit params contient les données devant être utilisées, le dictionnaire ne doit pas être 
	   utilisé, dans ce cas
	  	=> force = true
	  	=> params contient les paramètres nécessaire à la création du module.

	"force" indique la phase. Lorsqu'il est à false, les mises à jour ne sont pas effectuées et 
	un message est placé dans le rapport. Si force est a true, les mises à jour sur effectuées.

=end
	def load_module(params, extern_id, report, force = false)

		if(force == true)
			if(params[:mtype] == "cours")
				res =  @cours_loader.load_a_cours(params, extern_id, report, force)
			else
				res = @ensemble_loader.load_an_ensemble(params, extern_id, report, force)
			end		
		else
			act = activite_exists?(extern_id, report)
			if(act == nil) 
				params[:mtype] = "ensemble"	
				res = @ensemble_loader.load_an_ensemble(params, extern_id, report, force)
			else
				if(is_cours?(act)) 
					params[:mtype] = "cours"
					res = @cours_loader.load_a_cours(params, extern_id, report, force)
				else
					params[:mtype] = "ensemble"
					res = @ensemble_loader.load_an_ensemble(params, extern_id, report, force)
				end
			end
		end

		# Si le module a été sauvegardé correctement, check des contraintes légales (non restrictives)
		mod = VersionManager.create_module(params)
    	if(res && !VersionManager.create_module(params).check_legal_constraints())
	    	mod.get_report.list.each do |m|
    			report.write(m,"warning")
	    	end
	    end

		# Ajout éventuel du rapport à la liste des rapports maintenue. 
		handle_reports(params[:sigles], report)

		return res

	end

	# Prise en compte d'un feedback
	# params est 
	#   - soit un ensemble de paramètres correspondant à un CoursObject ou EnsembleObject
	#	- soit ":keep", indiquant, lors d'un avis de mise à jour, que les données actuelles doivent être
	#     conservées 
	def set_feedback(params, user_comment)
		if(@state == :wait_feedback)
			if(params == :keep)
				@feedback = :keep
			else
				@feedback = {:params => params, :user_comment => user_comment}
				PmoduleObject.adapt_types(@feedback[:params])
			end
			@state = :feedback_received
		end
	end

=begin

	Chargement du prochain module, sur base de l'état de la pile actuelle, de l'état du loader, 
	et d'un éventuel feedback recu.

	Procédure : load_next est appelé, si le chargement s'est correctement effectué,
	load_next peut être réinvoquée pour charger le module suivant. Si le chargement
	a été interrompu de par la nécessité d'une intervention de l'utilisateur, load_next
	ne doit être réappellée qu'après avoir donné un feedback via "set_feedback", permettant
	au loader d'accomplir sa tâche et de charger le module qui ne l'a pas été la première fois.

	Notons qu'il est possible que le feedback ne soit pas valable, dans ce cas un autre feedback
	est attendu, jusqu'à ce qu'il soit valable. Le module ne sera importé que lorsque le feedback
	sera valable.

=end	
	def load_next()

		# Si l'état est feedback_received
		if(@state == :feedback_received)

			# Lance la procédure de prise en compte de feedback pour charger un module.
			return feedback_received_routine() 
		
		# Sinon
		else 

			# Cas ou plus rien n'est à charger pour la racine sélectionnée, la pile est vide
			if(@state == :waiting && (@stack == nil || @stack.empty?))
				@last_answ = :empty
				return @last_answ
			end

			# Cas normal (premier load_next, ou bien juste après un import de module réussi)
			if(@state == :waiting)
				return waiting_routine()

			# cas ou le loader attend un feedback qu'il n'a pas recu
			elsif(@state == :wait_feedback)	
				return wait_feedback_routine()
			
			# Cas ne devant pas se produire, renvoie l'état pour débugger
			else
				return @state
			end
		
		end

	end

private 

	# Si "report" n'est pas vide, "@reports" le contiendra, sinon "@reports" ne contiendra 
	# aucun rapport correspondant à "sigle"
	def handle_reports(sigle, report)
		# Si le rapport contient au moins un message, l'ajoute à la liste des rapports.
		if(!report.empty?)
			# Si le rapport n'est pas vide, le sauvegarde (écrase éventuellement une ancienne version)
			@reports[sigle] = report
		else
			# Si le rapport est vide, supprime une éventuelle ancienne version
			@reports.delete(sigle)
		end
	end

	# Revoie la valeur du flag utilisé dans une réponse sur base du résultat
	# d'un chargement du module (true ou false) et du contenu du rapport.
	def get_flag(value, report)
		if(value == true)
			return "valid"
		else
			if(report.categories?.index("update") != nil)
				return "update"
			else
				return "error"
			end
		end
	end

	# Gestion du cas ou un feedback était attendu, et qu'il a été
	# recu. Nouvelle tentative d'import du module.
	def feedback_received_routine()

		report = Report.new()
		params = {}
		flag = nil

		# Si :keep, ne rien faire puisque l'utilisateur souhaite garder une version actuelle
		if(@feedback == :keep)
			flag = "valid"		
		else
		  	
		  	# Sinon, récupère les paramètres
			params = @feedback[:params]
			
			# Etabli la liste des différences avec ce qui était chargé depuis les fichiers
			i_c = build_diff(@old_params, params).join("; ")
			
			# Ajout les différence dans le champ prévu à cet effet
			params[:import_commentaire] = i_c

			# Tente un nouveau chagement du module avec le paramètre force mis à true.
			r = load_module(params, nil, report, true)
		
			# Récupère le flag en fonction de la réponse et du rapport.
			flag = get_flag(r, report)
		
		end
		
		# Adapte l'état en fonction de si l'import a réussi ou non
		if(flag == "valid")
			@state = :waiting
		else
			@state = :wait_feedback
		end

		@last_answ =  build_answere(params, report, flag)
		return @last_answ

	end

	# Gestion du cas "normal", lors d'une première tentative d'import du prochain module.
	def waiting_routine()

		report = Report.new()
		params = {}

		extern_id = @stack.pop()

		# Tente de charger le module
		r = load_module(params, extern_id, report, false)

		# Récupère le flag en fonction de la réponse et du rapport.
		flag = get_flag(r, report)

		# Si flag indique une mise à jour, récupère le module de la DB correspondant
		if(flag == "update")
			current = recover_current_module(params[:sigles], params[:mtype])
		end

		# Adapte l'état en fonction de si l'import a réussi ou non
		if(flag == "valid")
			@state = :waiting
		else
			@old_params = params
			@state = :wait_feedback
		end

		@last_answ =  build_answere(params, report, flag, current)
		return @last_answ

	end

	# Cas ou le loader attend un feedback qu'il n'a pas recu
	def wait_feedback_routine()
		return @last_answ
	end

	# Charge un module de la base de donnée sur base de son sigle
	def recover_current_module(sigle, mtype)
		current = nil
		id = PmoduleObject.id?(sigle)
		if(mtype == "cours")
		   	current = CoursObject.new()
		   	current.load(id)
		elsif(mtype == "ensemble")
		   	current = EnsembleObject.new()
		   	current.load(id)
		end
		return current		
	end

	# Renvoie true si les données d'un dictionnaire correspondant à un module
	# indique qu'il est question d'un cours.
	def is_cours?(act)
		return act["TYPE_ELE"] != "0"
	end

	# Renvoie true si extern_id correspond a une entrée dans la table "activites"
	def activite_exists?(extern_id, report)
		act = @hashes["activites"][extern_id]
		if(act == nil || act[0] == nil) 
			report.write("Impossible de charger correctement ce module, aucune correspondance dans la table 'activites' (table de description des modules)","error")
			return nil
		else
			return act[0]
		end
	end

	def build_stack_aux(extern_id, parent, module_loader)
		# Le contenu est un cours, la récursion s'arrête
		if(@hashes["EPL_grp"][extern_id] == nil)
			return
		else 
			# Le contenu est un ensemble, appel récursif sur le contenu
			@hashes["EPL_grp"][extern_id].each do |row|
				
				# Récupératon du sigle de l'élément contenu traité acutellement
				s = module_loader.build_sigle(row["NUM_GRP"])
				
				# Ajout en tant qu'enfant du noeud précédent
				n = Node.new(s)
				parent.add_child(n)

				# Ajout dans la pile
				@stack << row["NUM_GRP"]
				
				# Récursion
				build_stack_aux(row["NUM_GRP"], n, module_loader)

			end
		end
	end

=begin

	Fait deux choses : 
	
	1. Construction de la pile correspondant à une racine sélectionnée (root). La pile 
	   contient toujours le contenu d'un ensemble "au dessus" de l'ensemble lui-même. 

	2. Construction d'un arbre pour lequel chaque noeud contient le sigle d'un module,
	   et a pour enfants le contenu du module correspondant au sigle.

	Revnoie true ou false en fonction de si la racine "root" existe ou non, ainsi que le
	noeud racine de l'arbre obtenu

=end
	def build_stack(root)

		@stack = []
		tree_root = nil
		module_loader = ModuleLoader.new(@hashes)
		
		# Parcours de toutes les racines
		@hashes["activites_root"].each_value do |r|
			r = r[0]

			# Si la racine est celle demandée
			if(r["RTRIM(INTIT_ABREGE)"]==root)
			
				# Récupère le sigle du module
				s = module_loader.build_sigle(r["NUM_ELE"])
				
				# L'ajoute en tant que racine de l'arbre
				tree_root = Node.new(s)
				
				# L'ajout comme premier module de la pile
				@stack << r["NUM_ELE"]

				# invoque le processus récursif
				build_stack_aux(r["NUM_ELE"], tree_root, module_loader)
				
				return true, tree_root
			end
		end

		return false, tree_root

	end

	# Renvoie la liste des différences entre deux dictionnaires de paramètres
	# Renvoie un dictionnaire de paires <self, other> contenant les valeurs
	# différentes (self correspond à old_params, et other à new_params).
	def build_diff(old_params, new_params)
		result = []
		o = nil

		# Manipulations nécessaire pour utiliser "compaire" sur le CoursObject ou l'EnsembleObject
		# correspondant au paramètres.
		if(old_params[:mtype] == "cours")
			o = CoursObject.new(old_params)
		elsif(old_params[:mtype] == "ensemble")
			o = EnsembleObject.new(old_params)
		end

		if(new_params[:sigles].is_a?(String))
			new_params[:sigles] = new_params[:sigles].split(", ")
		end
		
		if(new_params[:mtype] == "cours")
			new_params[:creditsMin] = new_params[:creditsMax]
		end

		diff = o.compaire(new_params)

		if(diff!=nil)
			diff.each_pair do |k, v|
				# Ne prend pas en compte le champ :import_commentaire
				if(k != :import_commentaire)
					result << ("" + k.to_s + " [ " + v[:self].to_s + " => " + v[:other].to_s + " ]")
				end
			end
		end
		return result
	end

=begin
	
	Construit la réponse que renverra load_next, valeur des champs
		flag : Peut valoire
			- "valid" : chargement réussi. 
			- "udpate" : une confirmation pour une mise à jour est nécessaire.
			- "error" : une ou plusieurs erreurs sont apparues.
		report : rapport obtenu après (tentative de) chargement du module.
		mod : module obtenu après chargement.
		stack_initial_size : taille de la pile après initialisation
		stack_current_size  : taille actuelle de la pile
		current : lorsque le flag est "update", contient le module correspondant, présent dans la DB

=end
	def build_answere(params, report, flag, current = nil)
		
		if(params[:mtype]=="cours")
			return {
				:flag => flag,
				:report => report, 
				:mod => CoursObject.new(params), 
				:stack_initial_size => @stack_initial_size, 
				:stack_current_size => @stack.length,
				:current => current
			}
		elsif(params[:mtype]=="ensemble")
			return {
				:flag => flag,
				:report => report, 
				:mod => EnsembleObject.new(params), 
				:stack_initial_size => @stack_initial_size, 
				:stack_current_size => @stack.length,
				:current => current
			}
		else
			return {
				:flag => flag,
				:report => report, 
				:mod => nil, 
				:stack_initial_size => @stack_initial_size, 
				:stack_current_size => @stack.length,
				:current => current
			}
		end
		
	end

	# Renvoie true si value, la valeur d'une colonne de fichier csv, est considérée comme valide.
	def self.valid_field?(value)
		return value!=nil && value.gsub(" ","")!=""
	end

end
