class CreateOpenerasPeople < ActiveRecord::Migration
  def change
    create_table :openeras_people do |t|

      t.string          :name, index: true

      t.text            :description

      t.string          :website_url
      t.string          :facebook_url
      t.string          :googel_plus_url
      t.string          :twitter_url
      t.string          :linked_in_url
      t.string          :xing_url
      t.string          :diaspora_url
      t.string          :email

      t.string          :meta_keywords

      t.belongs_to      :contact

      t.iox_document_defaults
      t.timestamps

    end
  end
end
