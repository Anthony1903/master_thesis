# encoding: utf-8

class LegalConstraintsChecker < ConstraintsChecker

    $legal_category = "Contraintes légales"

    # Bornes imposées aux crédits

    $finalite_voc_min = 30
    $finalite_voc_max = 30

    $option_voc_min = 15
    $option_voc_max = 30

    $memoire_voc_min = 15
    $memoire_voc_max = 29

    def check_all()
        if !check_prog_master60 then return false end
        if !check_prog_master120 then return false end
        if !check_prog_bac then return false end
        if !check_voc_finalite then return false end
        if !check_voc_option then return false end
        if !check_voc_memoire then return false end
        return true
    end

    # Si l'intitulé de target contient les mots clés "master" et "60", alors il doit être possible
    # étant donné le contenu du module, de faire une sélection de 60 crédits strictement. 
    # Renvoie true si la contrainte est vérifiée, false sinon.
    def check_prog_master60()
        raise 'Try to use an abstract method'
    end

    # Si l'intitulé de target contient les mots clés "master" et "120", alors il doit être possible
    # étant donné le contenu du module, de faire une sélection de 120 crédits strictement. 
    # Renvoie true si la contrainte est vérifiée, false sinon.
    def check_prog_master120()
        raise 'Try to use an abstract method'
    end

    # Si l'intitulé de target contient le mot clé "bac", alors il doit être possible
    # étant donné le contenu du module, de faire une sélection de 180 crédits strictement. 
    # Renvoie true si la contrainte est vérifiée, false sinon.
    def check_prog_bac()
        raise 'Try to use an abstract method'
    end

    # Si l'intitulé de target contient le mot clé "finalité", alors ses crédits doivent être repris entre
    # les bornes finalite_voc_min et finalite_voc_max
    # Renvoie true si la contrainte est vérifiée, false sinon.
    def check_voc_finalite()
        raise 'Try to use an abstract method'
    end

    # Si l'intitulé de target contient le mot clé "option", alors ses crédits doivent être repris entre
    # les bornes option_voc_min et option_voc_max
    # Renvoie true si la contrainte est vérifiée, false sinon.
    def check_voc_option()
        raise 'Try to use an abstract method'
    end

    # Si l'intitulé de target contient le mot clé "memoire", alors ses crédits doivent être repris entre
    # les bornes memoire_voc_min et memoire_voc_max
    # Renvoie true si la contrainte est vérifiée, false sinon.
    def check_voc_memoire()
        raise 'Try to use an abstract method'
    end

private

    # Renvoie true si les créditsMin et créditsMax correspondent aux bornes passées en paramètres. 
    # Renvoie systématiquement true si le mot "word" ne figure pas dans l'intitulé
    def check_bounds(mod, bound_on_min, bound_on_max, word)

        if(mod.intitule == nil)
            return true
        end

        if(mod.intitule.gsub('é','e').downcase.index(word.gsub('é','e').downcase) != nil)
            if(mod.creditsMin < bound_on_min || mod.creditsMax > bound_on_max)
                @report.write("Tout intitulé contenant le mot #{word} doit avoir un minimum de #{bound_on_min} crédits et un maximum de #{bound_on_max} crédits", $legal_category )
                return false
            end
        end
        
        return true
    
    end

end