require 'test_helper'

class LogicalExpressionTest < ActiveSupport::TestCase

    test "evaluate" do

        l = LogicalExpression.new("((a1 & a2) | a42) && (!a4 ^ a1)") # ^ = xor

        assert l.evaluate(["a42","a1"]) == false
        assert l.evaluate(["a42","a42"]) == true 
        assert l.evaluate(["a42","a4"]) == false 
        assert l.evaluate(["a3","a5","a6","a7"]) == false
        assert l.evaluate(["a3","a5","a6","a7", "a1","a2","a4"]) == true 
        assert l.evaluate([]) == false 
        assert l.evaluate(nil) == false
        assert l.evaluate([""]) == false 

        l = LogicalExpression.new("!a1 & !a2 & !a3")
        assert l.evaluate("") == true 

        l = LogicalExpression.new("")
        assert l.evaluate("") == true 

        l = LogicalExpression.new("        ")
        assert l.evaluate("") == true 

        l = LogicalExpression.new(nil)
        assert l.evaluate("") == true 

    end

    test "well_formed?" do 

        assert LogicalExpression.new("a").well_formed?()
        assert LogicalExpression.new("(((((a)))))").well_formed?()
        assert LogicalExpression.new("a & b | c ^ d && e || f").well_formed?()
        assert LogicalExpression.new("((a & b) | c) ^ (d) && (e || f)").well_formed?()
        assert LogicalExpression.new("(() | c) ^ (d) && (e || f)").well_formed?()

        assert !LogicalExpression.new("").well_formed?()
        assert !LogicalExpression.new(nil).well_formed?()
        assert !LogicalExpression.new("(").well_formed?()
        assert !LogicalExpression.new(")").well_formed?()
        assert !LogicalExpression.new("()").well_formed?()
        assert !LogicalExpression.new("(  )").well_formed?()
        assert !LogicalExpression.new("a a").well_formed?()
        assert !LogicalExpression.new("((a & b | c) ^ (d) && (e || f)").well_formed?()
        assert !LogicalExpression.new("((a & b) | ) ^ (d) && (e || f)").well_formed?()
        assert !LogicalExpression.new("((a & b) | c)  (d) && (e || f)").well_formed?()
        assert !LogicalExpression.new("(((((a))))").well_formed?()

    end

    test "extract_variables" do 

        assert LogicalExpression.new("").extract_variables().empty?
        assert LogicalExpression.new(nil).extract_variables().empty?
        assert LogicalExpression.new("a").extract_variables() == ["a"]
        assert LogicalExpression.new("a & b").extract_variables().sort == ["a", "b"]
        assert LogicalExpression.new("(((a & b || ! c ^ d)) & b)").extract_variables().sort == ["a", "b","c","d"]
    
    end

end