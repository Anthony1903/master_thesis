class CreateCoursContenus < ActiveRecord::Migration
  def change
    create_table :cours_contenus do |t|
      t.integer :pmodule_id,       :null => false
      t.float :dureeCours,         :null => false
      t.float :dureeTP,            :null => false
      t.integer :quadri
      t.string :professeur

      t.timestamps
    end
    add_index :cours_contenus, :pmodule_id, :unique => true
  end
end
