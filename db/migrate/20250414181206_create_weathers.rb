class CreateWeathers < ActiveRecord::Migration[8.0]
  def change
    create_table :weathers do |t|
      t.string :zipcode, null: false
      t.decimal :temperature
      t.string :condition
      
      t.timestamps
    end

    add_index :weathers, :zipcode, unique: true
  end
end
