class Report

	def initialize()
		@content = {}
	end

	# Ecrit "data" dans le rapport, dans la catégorie "category" 
	def write(data, category)
		if(@content[category] == nil)
			@content[category] = [data]
		else
			@content[category] << data			
		end
	end

	# Renvoie le contenu d'une catégorie
	def get_category(category)
		return @content[category]
	end

	# Renvoie true si le rapport est vide, false sinon
	def empty?()
		return @content.empty?
	end

	# Vide le rapport
	def erase()
		@content = {}
	end

	# Renvoie la liste des catégories existantes
	def categories?()
		return @content.keys
	end

	# Supprime une catégorie et le contenu lié
	def remove_category(cat)
		@content.delete(cat)
	end

	# Fusionne deux rapports, incluant le contenu de other_report dans le rapport self
	def merge(other_report)
		if(!other_report.kind_of?(Report))
			return false
		else
			other_report.categories?.each do |c|
				other_report.get_category(c).each do |line|
					write(line, c)
				end
			end
			return true
		end
	end

	# Renvoie la liste des données écrites, toutes catégories confondues
	def list()
		result = []
		@content.each_value do |cat|
			cat.each do |v|
				result << v
			end
		end
		return result
	end

	# Renvoie une représentaion du contenu du rapport sous forme de chaine de caractères
	def to_s()
		result = []
		@content.each_pair do |k,v|
			tmp = ""+ k.to_s + " : "
			list = []
			v.each do |line|
				list << line.to_s  
			end
			tmp += list.join(", ")
			result << tmp
		end
		return result.join(" ; ")
	end
	
end
