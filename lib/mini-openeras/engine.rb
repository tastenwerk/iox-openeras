require 'iox/engine'

module MiniOpeneras

  class Engine < ::Rails::Engine

    isolate_namespace Openeras

    initializer :assets do |config|
      Rails.application.config.assets.precompile += %w(
        3rdparty/leaflet.js
        3rdparty/leaflet.css
        3rdparty/leaflet.ie.css
        3rdparty/leafletjs/*
        3rdparty/images/marker-icon.png
        3rdparty/images/marker-shadow.png
        3rdparty/images/*.png
        openeras/common.js
        openeras/common.css
      )

    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

  end

end
