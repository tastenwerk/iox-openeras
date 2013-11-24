class CreateOpenerasPrices < ActiveRecord::Migration
  def change
    create_table :openeras_prices do |t|

      t.string          :name
      t.string          :note
      t.boolean         :template, default: false
      t.float           :price

    end
  end
end
