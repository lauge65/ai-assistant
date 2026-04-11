class AddSummaryOpenedToContexts < ActiveRecord::Migration[7.1]
  def change
    add_column :contexts, :summary_opened, :boolean, default: false, null: false
  end
end
