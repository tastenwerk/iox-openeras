# encoding: utf-8

module Openeras
  class LabeledItem < ActiveRecord::Base

    belongs_to  :label

    belongs_to  :project
    belongs_to  :event
    belongs_to  :venue
    
  end
end