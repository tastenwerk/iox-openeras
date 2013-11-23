module Openeras
  class PeopleController < Iox::ApplicationController

    before_filter :authenticate!

    def index
      @people = Person.where('')
      if params[:query] && !params[:query].blank?
        @people.where("name LIKE ?", "%#{params[:query]}")
      end
      @total = @people.count
      render json: { items: @people.load, total: @total }
    end

  end
end