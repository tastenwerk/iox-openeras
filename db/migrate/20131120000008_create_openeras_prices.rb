class CreateOpenerasPrices < ActiveRecord::Migration
  def change
    create_table :openeras_prices do |t|

      t.string          :name
      t.float           :price

    end
  end
end
