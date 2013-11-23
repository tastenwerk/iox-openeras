module Openeras
  class Person < ActiveRecord::Base

    acts_as_iox_document

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    has_many    :images, -> { order(:position) }, class_name: 'Openeras::File', dependent: :destroy

    has_many    :labeled_items, dependent: :destroy
    has_many    :labels, through: :labeled_items

  end

end
