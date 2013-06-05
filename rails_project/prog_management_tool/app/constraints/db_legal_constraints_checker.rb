# encoding: utf-8

class DbLegalConstraintsChecker < LegalConstraintsChecker

=begin
        
    Voire LegalConstraintsChecker pour plus d'explications

=end

    def check_prog_master60()
        if @target.mtype == "cours" then return true end
        if(@target == nil || @target.intitule == nil)
            return true
        end
        intit = @target.intitule.downcase
        if(intit.include?("master") && intit.include?("60"))
            r =  DbStructuralConstraintsChecker.check_strict_credits(@target, 60)
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
        if @target.mtype == "cours" then return true end
        if(@target == nil || @target.intitule == nil)
            return true
        end
        intit = @target.intitule.downcase
        if(intit.include?("master") && intit.include?("120"))
            r =  DbStructuralConstraintsChecker.check_strict_credits(@target, 120)
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
        if @target.mtype == "cours" then return true end
        if(@target == nil || @target.intitule == nil)
            return true
        end
        if(@target.intitule.downcase.include?("bac"))
            r =  DbStructuralConstraintsChecker.check_strict_credits(@target, 180)
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
        if @target.mtype == "cours" then return true end
        return check_bounds(@target, $finalite_voc_min, $finalite_voc_max, 'finalite')
    end

    def check_voc_option()
        if @target.mtype == "cours" then return true end
        return check_bounds(@target, $option_voc_min, $option_voc_max, 'option')
    end

    def check_voc_memoire()
        return check_bounds(@target, $memoire_voc_min, $memoire_voc_max, 'memoire')
    end

end