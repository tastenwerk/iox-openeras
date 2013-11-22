class CreateOpenerasEvents < ActiveRecord::Migration
  def change
    create_table :openeras_events do |t|

      t.string        :description
      t.string        :additional_note

      t.datetime      :starts_at, index: true
      t.datetime      :ends_at

      t.integer       :price_from # changed to float in change_prices
      t.integer       :price_to # changed to float in change_prices
      t.string        :reductions

      t.string        :event_type, index: true

      t.text          :tickets_url
      t.string        :tickets_phone
      t.text          :tickets_other

      t.integer       :creator_id # DEPRECATED

      t.integer       :created_by
      t.integer       :updated_by

      t.integer       :festival_id

      t.belongs_to    :project
      t.belongs_to    :venue

      t.integer       :import_foreign_db_id
      t.string        :import_foreign_db_name

      t.timestamps
    end
  end
end
