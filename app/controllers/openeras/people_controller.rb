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

    def destroy
      if @person = Person.find_by_id( params[:id] )
        if @person.destroy
          flash.now.notice = t('openeras.person.removed', name: @person.name)
        else
          flash.now.alert = t('openeras.person.removing_failed', name: @person.name)
        end
      else
        notify_404
      end
      render json: { item: @person, success: flash[:alert].blank?, flash: flash }
    end

    private

    def person_params
      params.require(:person).permit(:name, :function)
    end

  end
end