require 'simplecov'

SimpleCov.start do
  add_group "Models",         "app/models"
  add_group "Controllers",    "app/controllers"
  add_group "Constraints",    "app/constraints"
  add_group "ImportManager",  "app/import_manager"
  add_group "Miscellaneous",  "app/miscellaneous"
  add_group "Objects",        "app/objects"
  add_group "Tree",           "app/tree"
end


ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

	def default_ensemble(sigle)
      params = {}
      params[:creditsMax] = 5
      params[:creditsMin] = 5
      params[:langue] = "fr"
      params[:sigles] = sigle 
      params[:dptCharge] = "INGI"
      params[:intitule] = "intitule"
      params[:contenu] = nil
      params[:commentaire] = "commentaire"
      params[:validite] = 2012
      params[:import_commentaire] = "import commentaire"
      params[:status] = "actuel"
      return EnsembleObject.new(params)
	end

	def default_cours(sigle)
      params = {}
      params[:creditsMax] = 5
      params[:creditsMin] = 5
      params[:dureeCours] = 5
      params[:dureeTP] = 5
      params[:sigles] = sigle 
      return CoursObject.new(params)
	end

  def default_diplome(root_sigle)

    params = {}
    params[:cycle] = "master"
    params[:sigle] = root_sigle + "_dipl"
    params[:facSigle] = "FACSIGLE"
    params[:root_sigle] = root_sigle

    return DiplomeObject.new(params)

  end

  def default_contrainte(sigle)
    return create_constraints_object("*", sigle, sigle)
  end

  def create_constraints_object(target, cond, effet)
      params = {}
      params[:target] = target
      params[:cond] = cond
      params[:effet] = effet
      return ContrainteObject.new(params)
  end 

end
