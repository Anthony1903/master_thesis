# encoding: utf-8

class CoursContenu < ActiveRecord::Base
  
    $DUREE_MIN = 0
    $DUREE_MAX = 1000

    attr_accessible :categorie, :dureeCours, :dureeTP, :professeur, :quadri, :pmodule_id

    belongs_to :pmodule

    validates_inclusion_of :quadri,
                         :allow_nil => true,
    			 	 	             :in => 1..2,	
                         :message => "Les quadrimestres valables sont 1, 2 ou aucun spécifié"
    			 	 	 
    validates :pmodule, :presence => true

    validates_numericality_of :dureeCours, 
                            :greater_than_or_equal_to => $DUREE_MIN,	
                            :less_than_or_equal_to => $DUREE_MAX,
                            :message => "La durée d'un cours doit être comprise entre "+$DUREE_MIN.to_s+" et "+$DUREE_MAX.to_s
                            
    validates_numericality_of :dureeTP,	 
                            :greater_than_or_equal_to => $DUREE_MIN,	
                            :less_than_or_equal_to => $DUREE_MAX,
                            :message => "La durée des TP doit être comprise entre "+$DUREE_MIN.to_s+" et "+$DUREE_MAX.to_s

    validate :valid_pmodule_id?

    # Check si le module n'est pas déjà un ensemble
    def valid_pmodule_id?

    if (Pmodule.find(pmodule_id).mtype == 'ensemble' || EnsembleContenu.find_by_pmodule_id(pmodule_id))
        errors.add(:pmodule_id, "Un ensemble ne peut avoir de contenu propre aux cours")
    end

    end

end
