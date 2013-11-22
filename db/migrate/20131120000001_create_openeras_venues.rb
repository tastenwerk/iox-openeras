class CreateOpenerasVenues < ActiveRecord::Migration
  def change
    create_table :openeras_venues do |t|

      t.string          :name, index: true

      t.text            :description
      t.string          :url
      t.string          :email
      t.string          :phone

      t.string          :country
      t.string          :city
      t.string          :zip
      t.string          :street

      t.string          :meta_keywords

      t.float           :lat
      t.float           :lng

      t.integer         :created_by

      t.timestamps
    end
  end
end
