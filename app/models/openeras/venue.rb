module Openeras
  class Venue < ActiveRecord::Base

    acts_as_iox_document
    include Iox::FileObject

    default_scope { where( deleted_at: nil ) }

    has_many :events, class_name: 'Openeras::Event', dependent: :nullify

    belongs_to :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    has_many :images, -> { order(:position) }, class_name: 'Openeras::File', dependent: :destroy

    validates :name, presence: true

    def projects(query='')
      pentries = []
      pentry_ids = []
      events.where(query).each do |e|
        next if pentry_ids.include? e.program_entry_id
        pentries << e.program_entry
        pentry_ids << e.program_entry_id
      end
      pentries #pentries.sort{ |a,b| false if( ! a.starts_at && !(a.starts_at && a.starts_at) <=> ( b.starts_at && b.starts_at ) }
    end

    def to_param
      [id, name.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      h[:events_num] = events.count
      h[:updater_name] = updater ? updater.full_name : (creator ? creator.full_name : ( import_foreign_db_name ? import_foreign_db_name : '' ))
      h
    end

  end

end
