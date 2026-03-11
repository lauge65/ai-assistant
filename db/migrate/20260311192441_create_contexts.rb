class CreateContexts < ActiveRecord::Migration[7.1]
  def change
    create_table :contexts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :level
      t.string :subject
      t.date :date

      t.timestamps
    end
  end
end
