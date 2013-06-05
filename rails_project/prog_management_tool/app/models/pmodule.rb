# encoding: utf-8

class Pmodule < ActiveRecord::Base

    $CREDITS_MIN = 0    # creditsMin compris entre CREDITS_MIN-CREDITS_MAX , creditsMax compris entre CREDITS_MIN-CREDITS_MAX
    $CREDITS_MAX = 200
    $VALIDITE_MIN = 2000
    $VALIDITE_MAX = 3000

    attr_accessible :creditsMax, :creditsMin, :intitule, :langue, :mtype, :dptCharge, :commentaire, :validite, :import_commentaire, :status

    # Spécification des "destroy" en chaine. Lorsqu'un pmodule est supprimé, plus aucune référence vers sont id doit exister dans la DB

    # Cas d'un cours, le cours_contenu doit être supprimé avec le pmodule
    has_one :cours_contenu,   :dependent => :destroy

    # Cas d'un ensemble, le diplome doit être supprimé avec le pmodule, ainsi que le contenu du module
    has_many :conteneur,      :class_name => 'EnsembleContenu',   :foreign_key => 'contenu_id',   :dependent => :destroy
    has_many :contenu,        :class_name => 'EnsembleContenu',   :foreign_key => 'pmodule_id',   :dependent => :destroy
    has_many :diplome,        :dependent => :destroy

    # Dans les deux cas, les contraintes et sigles liées au module doivent être supprimée avec le pmodule
    has_many :contrainte,    :dependent => :destroy
    has_many :sigle,         :dependent => :destroy

    validates_inclusion_of :mtype,
                           :in => %w(cours ensemble),
                           :message => "Le type d'un module ne peut être que 'cours' ou 'ensemble'"

    validates_inclusion_of :langue,
                           :in => %w(fr angl fr-angl),
                           :message => "La langue associée à un module doit être 'fr', 'angl' ou 'fr-angl'"

    validates_inclusion_of :status,
                           :in => %w(archive actuel future),
                           :message => "Le status d'un module doit être 'archive', 'actuel' ou 'future'"

    validates_numericality_of :creditsMin, 
                              :greater_than_or_equal_to => $CREDITS_MIN, 
                              :less_than_or_equal_to => $CREDITS_MAX,
                              :message => "La valeur des crédits minimum d'un module doit être comprise entre "+$CREDITS_MIN.to_s+" et "+$CREDITS_MAX.to_s

    validates_numericality_of :creditsMax,  
                              :greater_than_or_equal_to => $CREDITS_MIN, 
                              :less_than_or_equal_to => $CREDITS_MAX,
                              :message => "La valeur des crédits maximum d'un module doit être comprise entre "+$CREDITS_MIN.to_s+" et "+$CREDITS_MAX.to_s

    validates_numericality_of :validite,
                              :allow_nil => true,
                              :greater_than_or_equal_to => $VALIDITE_MIN, 
                              :less_than_or_equal_to => $VALIDITE_MAX,
                              :message => "La valeur du champ 'validite' doit être comprise entre "+$VALIDITE_MIN.to_s+" et "+$VALIDITE_MAX.to_s


    validate :valid_pair_of_credits?

    # Check si creditsMax >= creditsMin 
    def valid_pair_of_credits?

        if creditsMax != nil && creditsMin != nil && creditsMax < creditsMin
            errors.add(:creditsMax, "La valeur des crédits maximum d'un module 
                doit être supérieure ou égale à celle des crédits minimum")
        end

    end

end
