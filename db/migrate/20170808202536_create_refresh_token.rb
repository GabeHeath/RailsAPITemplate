class CreateRefreshToken < ActiveRecord::Migration[5.0]
  def change
    create_table :refresh_tokens do |t|
      t.string :user_id
      t.string :value

      t.timestamps
    end
  end
end
