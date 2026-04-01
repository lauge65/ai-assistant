class CreatePodcastScripts < ActiveRecord::Migration[7.1]
  def change
    create_table :podcast_scripts do |t|
      t.references :context, null: false, foreign_key: true
      t.text :content
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
