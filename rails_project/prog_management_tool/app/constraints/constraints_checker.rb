# encoding: utf-8

class ConstraintsChecker

    attr_accessor :target, :report

=begin
    
    L'objet rapport doit contenir un message d'erreur par contrainte violée
    après l'application d'une vérification la cible. La catégorie du message
    dépend de la catégorie de contrainte vérifiée.
    
=end
     
    def initialize(target)
        @target = target
        @report = Report.new() 
    end

    def check_all()
        raise 'Try to use an abstract method'
    end

end