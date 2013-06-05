class CreateContraintes < ActiveRecord::Migration
  def change
    create_table :contraintes do |t|
      t.integer :pmodule_id, 	:null => false
      t.string :cond, 			:null => false
      t.string :effet, 			:null => false

      t.timestamps
    end
    add_index :contraintes, [:pmodule_id, :cond, :effet], :unique => true
  end
end
