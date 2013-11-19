module Iox
  class EnsemblePicture < ActiveRecord::Base

    Paperclip.interpolates :ensemble_id do |attachment, style|
      attachment.instance.ensemble_id
    end

    include Iox::FileObject

    # paperclip plugin
    has_attached_file :file,
                      :styles => Rails.configuration.iox.venue_picture_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/:class/:ensemble_id/:style/:updated_at_:basename.:extension"

    validates_attachment :file,
                        attachment_presence: true,
                        content_type: { :content_type => ['image/jpg', 'image/png', 'image/jpeg', 'image/gif'] },
                        size: { in: 0..10.megabytes },
                        on: :create

    belongs_to :ensemble

  end
end