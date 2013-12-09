module Openeras
  class File < ActiveRecord::Base

    attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    belongs_to :fileable, polymorphic: true

    Paperclip.interpolates :rel_id do |attachment, style|
      attachment.instance.fileable_id
    end

    include Iox::FileObject

    # paperclip plugin
    has_attached_file :file,
                      processors: [ :cropper ],
                      :styles => Rails.configuration.iox.webfile_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/:class/:rel_id/:style/:id_:basename.:extension"

    validates_attachment :file,
                        attachment_presence: true,
                        dimensions: { :width => 300, :height => 300 },
                        content_type: { content_type: %w( 
                                        image/jpg 
                                        image/png 
                                        image/jpeg 
                                        image/gif 
                                        application/pdf 
                                        application/mp3 
                                        application/x-mp3 
                                        audio/mpeg 
                                        audio/mp3 
                                        application/msword 
                                        application/vnd.openxmlformats-officedocument.wordprocessingml.document 
                                        )
                        },
                        size: { in: 0..10.megabytes },
                        on: :create

    before_post_process :skip_for_audio, :skip_for_pdf

    def skip_for_audio
      ! %w(application/mp3 application/x-mp3 audio/mpeg audio/mp3 audio/ogg application/ogg).include?(file_content_type)
    end

    def skip_for_pdf
      ! %w(application/pdf).include?(file_content_type)
    end

    def as_json(options = { })
      h = super(options)
      h[:thumb_url] = gen_thumb_url
      h[:original_url] = file.url(:original)
      h
    end

    serialize :offset_coords, Hash

    def get_offset_styles( size )
      x = 0
      y = 0
      size = size.to_s
      if offset_coords.has_key? size
        x = offset_coords[size]['x']
        y = offset_coords[size]['y']
      end
      "top: #{y}px; left: #{x}px;"
    end

    def set_offset_styles( size, x, y )
      self.offset_coords[size] = {}
      self.offset_coords[size]['x'] = x
      self.offset_coords[size]['y'] = y
      x = x.to_i * -1
      y = y.to_i * -1
      self.crop_x = x.to_i < 0 ? "#{x}" : "+#{x}"
      self.crop_y = y.to_i < 0 ? "#{y}" : "+#{y}"
      self.crop_w = get_dim( size, 'w' )
      self.crop_h = get_dim( size, 'h' )
      file.reprocess! size.to_sym
    end

    # returns the dimensions given by size
    # to shrink original image and make it
    # fit into the smaller version's box
    def get_dim_w_or_h( size, orig=false )
      puts "dims: #{get_dim(:original, 'w')} x #{get_dim(:original, 'h')}"
      if get_dim( :original, 'w', orig ) < get_dim( :original, 'h', orig )
        return "width: #{get_dim( size, 'w', orig )}px;"
      else
        return "height: #{get_dim( size, 'h', orig )}px;"
      end
    end

    def get_dim( req_size, w_or_h, orig=false )
      Rails.configuration.iox.webfile_sizes.each_pair do |size, dim|

        next unless dim.include?('x') # break if no 'x'

        if req_size.to_s == size.to_s
          width = dim.split('x')[0]
          height = dim.split('x')[1].sub(/[\>\<\^\!\#]/,'')
          if orig
            geo = Paperclip::Geometry.from_file(file.path(req_size))
            return w_or_h.include?('w') ? geo.width : geo.height
          else
            return w_or_h.include?('w') ? width.to_i : height.to_i
          end
        end

      end

    end

    def cropping?
      crop_x && crop_y && crop_w && crop_h
    end

    def to_param
      [id, name.parameterize].join("-")
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
