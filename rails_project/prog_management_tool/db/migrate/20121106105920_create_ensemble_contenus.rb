class CreateEnsembleContenus < ActiveRecord::Migration
  def change
    create_table :ensemble_contenus do |t|
      t.integer :pmodule_id,	:null => false
      t.integer :contenu_id, 	:null => false
      t.string :annee, 			  :null => false
      t.boolean	:obligatoire,	:null => false

      t.timestamps
    end
    add_index :ensemble_contenus, [:pmodule_id, :contenu_id], :unique => true
  end
end
