class CreateOpenerasLabels < ActiveRecord::Migration
  def change
    create_table :openeras_labels do |t|

      t.string      :name
      t.integer     :parent_id
      t.string      :type

      t.iox_document_defaults

      t.timestamps

    end
  end
end