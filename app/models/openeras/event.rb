module Openeras
  class Event < ActiveRecord::Base

    belongs_to :project, class_name: 'Openeras::Project', touch: true

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    belongs_to  :venue

    has_many    :labeled_items, dependent: :destroy
    has_many    :labels, through: :labeled_items

    has_many :event_prices, dependent: :delete_all
    has_many :prices, through: :event_prices

    before_save :update_start_end_time

    validate :starts_at, presence: true
    validate :ends_at, presence: true
    validate :venue_id, presence: true

    def as_json(options = { })
      h = super(options)
      h[:venue_name] = venue.name if venue
      h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : '' )
      h
    end

    private

    def update_start_end_time
      if new_record? && ends_at.blank? && program_entry && program_entry.duration && program_entry.duration > 0
        self.ends_at = starts_at+program_entry.duration.minutes
      end
    end

  end
end