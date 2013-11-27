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
    after_save :set_default_prices, :update_project_start_end_dates

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
      if all_day
        self.starts_at = self.starts_at.beginning_of_day
        self.ends_at = self.ends_at.end_of_day
      end
    end

    def set_default_prices
      Price.where( template: true ).each do |p|
        event_prices.create! price_id: p.id
      end
    end

    def update_project_start_end_dates
      project.starts_at = starts_at if( project.starts_at.nil? || starts_at < project.starts_at )
      project.ends_at = ends_at if( project.ends_at.nil? || ends_at > project.ends_at )
      project.save
    end

  end
end