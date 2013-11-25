module Openeras
  class File < ActiveRecord::Base

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    belongs_to :fileable, polymorphic: true

    Paperclip.interpolates :rel_id do |attachment, style|
      attachment.instance.fileable_id
    end

    include Iox::FileObject

    # paperclip plugin
    has_attached_file :file,
                      :styles => Rails.configuration.iox.webfile_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/:class/:rel_id/:style/:updated_at_:basename.:extension"

    validates_attachment :file,
                        attachment_presence: true,
                        dimensions: { :width => 300, :height => 300 },
                        content_type: { :content_type => ['image/jpg', 'image/png', 'image/jpeg', 'image/gif'] },
                        size: { in: 0..10.megabytes },
                        on: :create

    validates_attachment :file, content_type: { 
      content_type: [ "application/pdf", 
                      "image/jpg", 
                      "image/png", 
                      "image/gif", 
                      "image/jpeg", 
                      'application/mp3', 
                      'application/x-mp3', 
                      'audio/mpeg', 
                      'audio/mp3' ] 
      }

    before_post_process :skip_for_audio

    def skip_for_audio
      ! %w(application/mp3 application/x-mp3 audio/mpeg audio/mp3 audio/ogg application/ogg).include?(file_content_type)
    end

    def as_json(options = { })
      h = super(options)
      h[:thumb_url] = gen_thumb_url
      h[:original_url] = file.url(:original)
      h
    end

    private

    def gen_thumb_url
      thmb = nil
      if file && !file.content_type.blank? 
        if file.content_type.include? 'image'
          thmb = file.url(:thumb)
        elsif file.content_type == 'application/pdf'
          thmb = file.url(:pdf_thumb)
        end
      end
      thmb
    end

  end
end