class AddProgressTrackingToContexts < ActiveRecord::Migration[7.1]
  def change
    change_table :contexts, bulk: true do |t|
      t.boolean :document_opened, default: false, null: false
      t.boolean :assistant_used, default: false, null: false
      t.boolean :podcast_opened, default: false, null: false
      t.boolean :revision_completed, default: false, null: false
    end
  end
end
