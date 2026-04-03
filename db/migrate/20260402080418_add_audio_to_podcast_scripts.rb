class AddAudioToPodcastScripts < ActiveRecord::Migration[7.1]
  def change
    add_column :podcast_scripts, :audio_status, :string, default: "pending"
  end
end
