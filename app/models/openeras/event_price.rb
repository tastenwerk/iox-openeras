module Openeras
  class EventPrice < ActiveRecord::Base

    belongs_to :price
    belongs_to :event

  end
end