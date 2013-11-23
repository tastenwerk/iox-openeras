class CreateOpenerasProjects < ActiveRecord::Migration
  def change
    create_table :openeras_projects do |t|

      t.string          :title, index: true
      t.string          :subtitle

      t.integer         :conflict_id

      t.date            :starts_at, index: true
      t.date            :ends_at, index: true

      t.text            :url

      t.integer         :organizer_id
      t.string          :coproduction

      t.string          :youtube_url
      t.string          :vimeo_url

      t.string          :categories, index: true

      t.integer         :duration
      t.boolean         :has_breaks
      t.integer         :age

      t.iox_document_defaults
      t.timestamps
      
    end
  end
end
