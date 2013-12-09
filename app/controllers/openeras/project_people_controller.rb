module Openeras
  class ProjectPeopleController < Iox::ApplicationController

    before_filter :authenticate!


    {"sort"=>{"0"=>{"field"=>"position", "dir"=>"asc"}},
    }
    def index
      @project = get_project
      @people = @project.project_people
      order = "position asc"
      if params[:sort] && params[:sort]['0']
        order = "#{params[:sort]['0'][:field]} #{params[:sort]['0'][:dir]}"
      end
      @people = @people.order(order).load
      render json: { items: @people, total: @people.size }
    end

    def create
      @project = get_project
      @person = Person.new person_params
      if @person.save
        if @project.project_people.create person: @person, function: params[:person][:function]
          flash.now.notice = t('openeras.person.saved', name: @person.name)
        else
          flash.now.alert = t('openeras.person.saving_failed')
        end
      else
        flash.now.alert = t('openeras.person.saving_failed')
      end
      render json: { item: @person, success: flash[:alert].blank?, flash: flash }
    end

    def update
      if @project_person = ProjectPerson.find_by_id( params[:id] )
        @person = @project_person.person
        if @project_person.person.update person_params
          if @project_person.update function: params[:person][:function]
            flash.now.notice = t('openeras.person.saved', name: @person.name)
          else
            flash.now.alert = t('openeras.person.saving_failed')
          end
        else
          flash.now.alert = t('openeras.person.saving_failed')
        end
      else
        notify_404
      end
      render json: { item: @person, success: flash[:alert].blank?, flash: flash }
    end

    def reorder
      errors = []
      params[:pp_ids].each_with_index do |project_person_id, i|
        if pp = ProjectPerson.find_by_id( project_person_id )
          errors << pp.errors.full_messages unless pp.update position: i
        else
          errors << "not found #{project_person_id}"
        end
      end
      if errors.size == 0
        flash.notice = t('project.people_order_saved')
      else
        flash.alert = t('project.people_order_could_not_be_saved')
      end
      render json: { success: flash[:alert].blank?, flash: flash }
    end

    def destroy
      if @project_person = ProjectPerson.find_by_id( params[:id] )
        @person = @project_person.person
        if @project_person.destroy
          flash.now.notice = t('openeras.project.removed_person', name: @person.name)
        else
          flash.now.alert = t('openeras.project.removing_person_failed', name: @person.name)
        end
      else
        notify_404
      end
      render json: { success: flash[:alert].blank?, flash: flash }
    end

    private

    def person_params
      params.require(:person).permit(:name, :function)
    end

    def setup_project_connection
      if @project = Project.find_by_id( params[:project_id] )
        return @project.project_people.create person_id: @project_person.id, function: @project_person.function
      end
    end

    def get_project
      return Project.find_by_id params[:project_id]
    end

  end
end
