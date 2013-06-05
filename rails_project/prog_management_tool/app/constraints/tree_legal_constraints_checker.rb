# encoding: utf-8

class TreeLegalConstraintsChecker < LegalConstraintsChecker

=begin
		
	Voire LegalConstraintsChecker pour plus d'explications

=end

	# target est un noeud contenant un module, et root la racine d'un arbre contenant target
	def initialize(target, root)
		super(target)
		@root = root
	end

	def check_prog_master60()
		if @target.data.mtype == "cours" then return true end
		if(@target == nil || @target.data == nil || @target.data.intitule == nil)
			return true
		end

		intit = @target.data.intitule.downcase
		if(intit.include?("master") && intit.include?("60"))
			r =  TreeStructuralConstraintsChecker.check_strict_credits(@target, 60, @root)
			if(!r)
				@report.write("Au moins une composition du programme doit valoir exactement 60 crédits (intitulé contient 'master 60')", $legal_category)
				return false
			else
				return true
			end
		else
			return true
		end
	end

	def check_prog_master120()
		if @target.data.mtype == "cours" then return true end
		if(@target == nil || @target.data == nil || @target.data.intitule == nil)
			return true
		end

		intit = @target.data.intitule.downcase
		if(intit.include?("master") && intit.include?("120"))
			r =  TreeStructuralConstraintsChecker.check_strict_credits(@target, 120, @root)
			if(!r)
				@report.write("Au moins une composition du programme doit valoir exactement 120 crédits (intitulé contient 'master 120')", $legal_category)
				return false
			else
				return true
			end
		else
			return true
		end
	end

	def check_prog_bac()
		if @target.data.mtype == "cours" then return true end
		if(@target == nil || @target.data == nil || @target.data.intitule == nil)
			return true
		end
		if(@target.data.intitule.downcase.include?("bac"))
			r =  TreeStructuralConstraintsChecker.check_strict_credits(@target, 180, @root)
			if(!r)
				@report.write("Au moins une composition du programme doit valoir exactement 180 crédits (intitulé contient 'bac')", $legal_category)
				return false
			else
				return true
			end
		else
			return true
		end
	end

	def check_voc_finalite()
		if @target.data.mtype == "cours" then return true end
		return check_bounds(@target.data, $finalite_voc_min, $finalite_voc_max, 'finalite')
	end

	def check_voc_option()
		if @target.data.mtype == "cours" then return true end
		return check_bounds(@target.data, $option_voc_min, $option_voc_max, 'option')
	end

	def check_voc_memoire()
		return check_bounds(@target.data, $memoire_voc_min, $memoire_voc_max, 'memoire')
	end

end