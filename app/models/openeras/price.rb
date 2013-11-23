module Openeras
  class Price < ActiveRecord::Base

    has_many :event_prices, dependent: :delete_all
    has_many :events, through: :event_prices

  end
end