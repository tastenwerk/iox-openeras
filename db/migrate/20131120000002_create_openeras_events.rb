class CreateOpenerasEvents < ActiveRecord::Migration
  def change
    create_table :openeras_events do |t|

      t.string        :description
      t.string        :additional_note

      t.datetime      :starts_at, index: true
      t.datetime      :ends_at
      t.boolean       :all_day

      t.integer       :available_seats

      t.string        :event_type, index: true

      t.text          :tickets_url
      t.string        :tickets_phone
      t.text          :tickets_other

      t.integer       :created_by
      t.integer       :updated_by

      t.integer       :festival_id

      t.belongs_to    :project
      t.belongs_to    :venue

      t.timestamps
    end
  end
end
