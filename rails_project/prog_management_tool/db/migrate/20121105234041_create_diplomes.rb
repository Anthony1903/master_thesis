class CreateDiplomes < ActiveRecord::Migration
  def change
    create_table :diplomes do |t|
      t.string :sigle,        :null => false
      t.string :cycle,        :null => false
      t.string :facSigle,     :null => false
      t.integer :pmodule_id,  :null => false

      t.timestamps
    end
    
    add_index :diplomes, :sigle, :unique => true
  end
end
