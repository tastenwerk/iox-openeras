# encoding: utf-8

module Openeras
  class Project < ActiveRecord::Base

    acts_as_iox_document

    attr_accessor :venue_id, :venue_name, :init_label_id

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'
    has_many    :events, -> { order(:starts_at) }, class_name: 'Openeras::Event', dependent: :delete_all
    has_many    :images, -> { order(:position) }, class_name: 'Openeras::File', dependent: :destroy

    has_many    :labeled_items
    has_many    :labels, through: :labeled_items

    validates   :title, presence: true, length: { in: 2..255 }
    validates   :subtitle, length: { maximum: 255 }
    validates   :meta_keywords, length: { maximum: 255 }
    validates   :meta_keywords, length: { maximum: 255 }
    validates   :age, inclusion: { in: 1..20 }, numericality: true, allow_blank: true
    validates   :duration, inclusion: { in: 1..960 }, numericality: true, allow_blank: true

    def venues
      v = ''
      if events.size > 0 and events.first.venue
        v << "<a href='/iox/venues/#{events.first.venue.id}'>#{events.first.venue.name}/edit</a>"
      end
      v
    end

    def to_param
      [id, title.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      h[:venue_id] = venue_id
      h[:venue_name] = venue_name
      h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : '' )
      h
    end

  end
end