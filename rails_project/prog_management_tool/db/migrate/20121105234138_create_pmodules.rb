class CreatePmodules < ActiveRecord::Migration
  def change
    create_table :pmodules  do |t|
      t.string :mtype,          :null => false
      t.integer :creditsMin,    :null => false
      t.integer :creditsMax,    :null => false
      t.text :intitule
      t.string :langue,         :null => false,   :default => "fr-angl"
      t.string :dptCharge
      t.text :commentaire
      t.integer :validite
      t.text :import_commentaire
      t.string :status,         :null => false,   :default => "actuel"

      t.timestamps
    end
  end
end
