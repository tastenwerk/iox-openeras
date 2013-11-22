]class CreateOpenerasFiles < ActiveRecord::Migration
  def change
    create_table :openeras_files do |t|

      t.attachment  :file
      t.string      :name
      t.string      :description
      t.string      :copyright
      t.integer     :position, default: 0

      t.belongs_to  :openeras_project
      t.belongs_to  :openeras_venue

      t.timestamps

    end
  end
end
