# encoding: utf-8

class Diplome < ActiveRecord::Base
	
    attr_accessible :cycle, :sigle, :facSigle, :pmodule_id
  
    belongs_to :pmodule

    validates_inclusion_of :cycle,
                           :in => %w(master bac master60 passerelle),
                           :message => "Les cycles valables sont: 'master', 'bac', 'master60' et 'passerelle'"

  	validates :pmodule, :presence => true

    validate :valid_pmodule_type?

    # Vérifie que le module racine est de type "ensemble"
    def valid_pmodule_type?
      
        if (Pmodule.find(pmodule_id).mtype != 'ensemble')
            errors.add(:pmodule_id, "Un diplome doit faire référence à un module de type ensemble")
        end
    
    end

end