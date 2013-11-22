class CreateOpenerasLabeledItems < ActiveRecord::Migration
  def change
    create_table :openeras_labeled_items do |t|

      t.belongs_to :label

      t.belongs_to :project
      t.belongs_to :event
      t.belongs_to :venue

      t.timestamps

    end
  end
end
