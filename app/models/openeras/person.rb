module Openeras
  class Person < ActiveRecord::Base

    acts_as_iox_document

    attr_accessor :function

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    has_many    :images, -> { order(:position) }, class_name: 'Openeras::File', dependent: :destroy

    has_many    :project_people, dependent: :destroy
    
    has_many    :labeled_items, dependent: :destroy
    has_many    :labels, through: :labeled_items

    def as_json(options = { })
      h = super(options)
      h[:function] = function
      h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : '' )
      h
    end

  end

end
