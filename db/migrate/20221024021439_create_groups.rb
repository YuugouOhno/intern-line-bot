class CreateGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :groups do |t|
      t.string :line_group_id, null: false

      t.timestamps
    end
    add_index :groups, :line_group_id, unique: true
  end
end
