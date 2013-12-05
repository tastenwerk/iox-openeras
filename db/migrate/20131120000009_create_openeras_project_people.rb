class CreateOpenerasProjectPeople < ActiveRecord::Migration
  def change
    create_table :openeras_project_people do |t|

      t.string          :function
      t.belongs_to      :project
      t.belongs_to      :person
      t.integer         :position
      t.timestamps

    end
  end
end
