class Sigle < ActiveRecord::Base

    attr_accessible :pmodule_id, :sigle

    belongs_to :pmodule

    validates_uniqueness_of :sigle

    validates :pmodule,    :presence => true

    validates_presence_of :sigle

end
