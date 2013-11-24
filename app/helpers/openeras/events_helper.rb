module Openeras

  module EventsHelper

    def get_venue_as_option
      return [] if @event.new_record? || !@event.venue
      return options_for_select([ [@event.venue.name, @event.venue.id] ], @event.venue.id )
    end

  end

end