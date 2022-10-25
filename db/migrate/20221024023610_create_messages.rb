class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.references :group, null: false, foreign_key: true
      t.timestamp :posted_at, null: false
      t.string :message_type, null: false
      t.string :user_id, null: false
      t.string :text
      
      t.timestamps
    end
  end
end
