class Contrainte < ActiveRecord::Base
  
	attr_accessible :cond, :effet, :pmodule_id

	belongs_to :pmodule

end
