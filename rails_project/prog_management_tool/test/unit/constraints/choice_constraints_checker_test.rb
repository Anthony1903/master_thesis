# encoding: utf-8

require 'test_helper'

class ChoiceConstraintsCheckerTest < ActiveSupport::TestCase

    test 'check_contrainte_target' do

        co = create_constraints_object("a", "b", "c")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_contrainte_target
        assert !ccc.report.empty?
        ccc.report.erase

        co2 = create_constraints_object("*", "b", "c")
        ccc2 = ChoiceConstraintsChecker.new(co2)
        assert ccc2.check_contrainte_target
        assert ccc2.report.empty?

        eo = default_ensemble("a")
        assert eo.save() > 0
        
        assert ccc.check_contrainte_target
        assert ccc.report.empty?
        ccc.report.erase

    end

    test 'check_condition' do

        co = create_constraints_object("*","a & b","c")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_condition()
        assert !ccc.report.empty?
        ccc.report.erase

        eo = default_ensemble("a")
        assert eo.save() > 0
        eo = default_ensemble("b")
        assert eo.save() > 0

        assert ccc.check_condition()
        assert ccc.report.empty?

        co = create_constraints_object("*","a || b & ((! a || ! b) ^ a)","c")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_condition()
        assert ccc.report.empty?

        co = create_constraints_object("*","a||b&((!a||!b)^a)","c")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_condition()
        assert ccc.report.empty?

        # Suppression d'une parenthèse nécessaire

        co = create_constraints_object("*","a || b & ((! a || ! b ^ a)","c")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_condition()
        assert !ccc.report.empty?
        ccc.report.erase

    end

    test 'check_effet' do

        # Syntaxe simple

        co = create_constraints_object("*","c","a & b")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        eo = default_ensemble("a")
        assert eo.save() > 0
        eo = default_ensemble("b")
        assert eo.save() > 0

        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","c","a && b & ((! a && ! b) & a)")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","c","a && b & ((! a && ! b & a)")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        # Syntaxe enrichie

        co = create_constraints_object("*","c","a && b & ((! a && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","c","a && T(b) & ((! a && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","c","C(a) && T(b) & ((! a && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","c","C(a) && T(b) & (( M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","c","C(a)&&T(b)&((M[a>b]&&!b)&E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        # Utilisation de sigles comprennant des lettres de la syntaxe enrichie

        eo = default_ensemble("MATH")
        assert eo.save() > 0
        eo = default_ensemble("AMA")
        assert eo.save() > 0
        eo = default_ensemble("E")
        assert eo.save() > 0
        eo = default_ensemble("T")
        assert eo.save() > 0

        co = create_constraints_object("*","c","MATH && AMA & ((! E && ! T) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        # Meme formule que ci-dessus mais avec des caractères importants supprimés (parenthèses, etc)

        co = create_constraints_object("*","c","C(a) && T(b) & ( M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","Ca) && T(b) & ( M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & ( M[a > b && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & ( M[a  b] && ! b) & E(a)")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        # Meme formule mais avec des connecteurs logiques non autorisés

        co = create_constraints_object("*","c","C(a) && T(b) & (( M[a > b] && ! b) | E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & (( M[a > b] && ! b) ^ E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        # Meme formule mais avec des connecteurs logiques mal utilisés

        co = create_constraints_object("*","c","C(a) && T!(b) & (( ! M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & !(( M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & (( ! M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","! C(a) && T(b) & (( M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) ! & (( M[a > b] && ! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & (( M[a > b] && !! b) & E(a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","C(a) && T(b) & (( M[a > b] && ! b) & E(!a))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

        co = create_constraints_object("*","c","!(!a)")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?
        ccc.report.erase

    end

    test 'valid_substitution?' do 

        # Cas ou la substitution entraine un cycle

        eo1 = default_ensemble("eo1")
        eo1.creditsMin = 5
        eo1.creditsMax = 5
        eo1.contenu = "eo2 1 false, eo3 1 false"
        
        eo2 = default_ensemble("eo2")
        eo2.creditsMin = 5
        eo2.creditsMax = 5
        
        eo3 = default_ensemble("eo3")
        eo3.creditsMin = 5
        eo3.creditsMax = 5

        eo1_bis = default_ensemble("eo1bis")        # eo1 -> eo1_bis = Valid
        eo1_bis.creditsMin = 5
        eo1_bis.creditsMax = 5
        eo1_bis.contenu = "eo2 1 true, eo3 1 false"

        eo1_ter = default_ensemble("eo1ter")        # eo1 -> eo1_ter = Invalid (cycle)
        eo1_ter.creditsMin = 5
        eo1_ter.creditsMax = 5
        eo1_ter.contenu = "eo1 1 true, eo3 1 false"

        assert eo3.save() > 0
        assert eo2.save() > 0
        assert eo1.save() > 0
        assert eo1_bis.save() > 0
        assert eo1_ter.save() > 0

        co = create_constraints_object("*","eo1","M[eo1>eo1bis]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.check_effet()
        assert ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo3]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()   # Car 2x le même contenu strictement pour eo1
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo1>eo1ter]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo1bis]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo1ter]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo1bis] & M[eo2>eo1ter]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo1ter] & M[eo2>eo1bis]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo1bis] & M[eo2>eo1bis]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        co = create_constraints_object("*","eo1","M[eo2>eo1ter] & M[eo2>eo1ter]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

        # Cas ou la substitution entraine une erreur dans les crédits

        eo1 = default_ensemble("eo12")
        eo1.creditsMin = 5
        eo1.creditsMax = 5
        eo1.contenu = "eo22 1 true, eo32 1 false"
        
        eo2 = default_ensemble("eo22")
        eo2.creditsMin = 5
        eo2.creditsMax = 5
        
        eo3 = default_ensemble("eo32")
        eo3.creditsMin = 5
        eo3.creditsMax = 5

        eo4 = default_ensemble("eo42")
        eo4.creditsMin = 6
        eo4.creditsMax = 6

        assert eo4.save() > 0
        assert eo3.save() > 0
        assert eo2.save() > 0
        assert eo1.save() > 0

        co = create_constraints_object("*","eo1","M[eo22>eo42]")
        ccc = ChoiceConstraintsChecker.new(co)
        assert !ccc.check_effet()
        assert !ccc.report.empty?

    end

    test 'triggered?' do
        
        co = create_constraints_object("*","(a || b) & (! a || ! b)","c")
        ccc = ChoiceConstraintsChecker.new(co)

        assert ccc.triggered?(["a"])
        assert ccc.triggered?(["b"])

        assert !ccc.triggered?([])
        assert !ccc.triggered?(nil)
        assert !ccc.triggered?(["a", "b"])

        co = create_constraints_object("*","!a","c")
        ccc = ChoiceConstraintsChecker.new(co)

        assert ccc.triggered?([])
        assert ccc.triggered?(nil)
        assert ccc.triggered?(["b"])

        assert !ccc.triggered?(["a"])

    end

    test 'extract_effects' do
        
        eo = default_ensemble("a")
        assert eo.save() > 0
        eo = default_ensemble("b")
        assert eo.save() > 0
        eo = default_ensemble("c")
        assert eo.save() > 0
        eo = default_ensemble("d")
        assert eo.save() > 0
        eo = default_ensemble("e")
        assert eo.save() > 0
        eo = default_ensemble("f")
        assert eo.save() > 0

        co = create_constraints_object("*","c","C(a) && T(b) & (( M[c > d] && ! e) & E(f))")
        ccc = ChoiceConstraintsChecker.new(co)
        res = ccc.extract_effects()
        hash = {"a" => "C", "b" => "T","c" => "d","e" => false,"f" => "E"}
        assert res == hash

        co = create_constraints_object("*","c","C(a) && T(a) & E(a)")
        ccc = ChoiceConstraintsChecker.new(co)
        res = ccc.extract_effects()
        hash = {"a" => "E"}
        assert res == hash

        co = create_constraints_object("*","c","a && T(b) & (( M[c > d] && ! e) & f)")
        ccc = ChoiceConstraintsChecker.new(co)
        res = ccc.extract_effects()
        hash = {"a" => true, "b" => "T","c" => "d","e" => false,"f" => true}
        assert res == hash

        co = create_constraints_object("*","c","a && T(b) & (( M[c > d] && ! e) & f) & M[c > e]")
        ccc = ChoiceConstraintsChecker.new(co)
        res = ccc.extract_effects()
        hash = {"a" => true, "b" => "T","c" => "e","e" => false,"f" => true}
        assert res == hash

    end

    test 'extract_sigles' do 
        
        # Cas de base
        
        co = create_constraints_object("*","a && b & (( c | d && ! e) & f)","C(g) && T(b) & (( M[h > i] && ! e) & E(j))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.extract_sigles.sort == ["a","b","c","d","e","f","g","h","i","j"].sort
        
        # Mélange entre symboles de type sigle et syntaxe

        co = create_constraints_object("*","M && I & (( T | C && ! M) & I )","C(F) && T(G) & (( M[M > K] && ! H) & E(E))")
        ccc = ChoiceConstraintsChecker.new(co)
        assert ccc.extract_sigles.sort == ["M","I","T","C","F","G","H","K","E"].sort

    end

    test 'check_all' do 

        eo = default_ensemble("a")
        assert eo.save() > 0
        eo = default_ensemble("b")
        assert eo.save() > 0

        co = create_constraints_object("*","a","b")
        ccc = ChoiceConstraintsChecker.new(co)

        assert ccc.check_all
        assert ccc.report.empty?

    end

end