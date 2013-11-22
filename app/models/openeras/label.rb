# encoding: utf-8

module Openeras
  class Label < ActiveRecord::Base

    acts_as_iox_document

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'
    has_many    :projects, dependent: :nullify
    has_many    :venues, dependent: :nullify
    has_many    :events, dependent: :nullify

    def as_json(options = { })
      h = super(options)
      h
    end

  end
end