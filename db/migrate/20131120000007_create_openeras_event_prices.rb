class CreateOpenerasEventPrices < ActiveRecord::Migration
  def change
    create_table :openeras_event_prices do |t|

      t.belongs_to      :event
      t.belongs_to      :price
      t.timestamps

    end
  end
end
