# encoding: utf-8

class DbFieldConstraintsChecker < FieldConstraintsChecker

=begin
		
	Voire FieldConstraintsChecker pour plus d'explications

=end

	def check_fields()
		return check_fields_glob(@target)
	end

	def check_content_existence()
		if(@target.mtype == "cours")
			return true
		end
		@target.get_content_array.each do |s, a, o|
			if(Sigle.find_by_sigle(s) == nil) 
				@report.write("#{s} n'existe pas dans la base de donnée", $field_category)
				return false
			end
		end
		return true
	end

	def check_content_duplications()
		return check_content_duplications_glob(@target)
	end

	# Renvoie un id unique pour le module de sigle "sigle"
	def get_uid(sigle)
		s = Sigle.find_by_sigle(sigle)
		if(s==nil)
			return sigle 
		else
			return s.pmodule_id
		end
	end


end