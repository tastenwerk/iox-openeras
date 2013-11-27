module Openeras
  class ProjectPeopleController < Iox::ApplicationController

    before_filter :authenticate!

    def index
      @project = get_project
      @people = @project.project_people.load
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