# encoding: utf-8

class EnsembleContenu < ActiveRecord::Base

    attr_accessible :annee, :contenu_id, :pmodule_id, :obligatoire

    belongs_to :pmodule

    belongs_to :contenu,
    		   :class_name => "Pmodule"

    validates_inclusion_of :annee,
            			   :in => %w(1 2 3 1-2 2-3 1-3 1-2-3),
                           :message => "Le champ 'année' doit obligatoirement contenir une des valeurs suivantes : '1', '2', '3', '1-2', '2-3', '1-3', '1-2-3'"

    validates_inclusion_of :obligatoire,
                           :in => [true, false],
                           :message => "Le champ 'obligatoire' doit valoir 'true' ou 'false'"


    validates :pmodule, :presence => true

    validates :contenu, :presence => true

    validate :valid_pmodule_id?

    # Check si le module n'est pas déjà un cours
    def valid_pmodule_id?

        if (Pmodule.find(pmodule_id).mtype == 'cours' || CoursContenu.find_by_pmodule_id(pmodule_id))
            errors.add(:pmodule_id, "Un cours ne peut avoir de contenu propre aux ensembles")
        end

    end

end
