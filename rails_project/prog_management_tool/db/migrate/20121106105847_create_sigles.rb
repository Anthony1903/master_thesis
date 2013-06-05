class CreateSigles < ActiveRecord::Migration
  def change
    create_table :sigles do |t|
      t.integer :pmodule_id, 	:null => false
      t.string :sigle, 			:null => false

      t.timestamps
    end
    add_index :sigles, :sigle, :unique => true
   end
end
