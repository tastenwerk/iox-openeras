module Openeras
  class ProjectPerson < ActiveRecord::Base
    belongs_to :person
    belongs_to :project

    def as_json(options = { })
      h = super(options)
      h[:person] = person
      h
    end

  end
end