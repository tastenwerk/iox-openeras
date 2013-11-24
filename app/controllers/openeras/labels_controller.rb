require_dependency "iox/application_controller"

module Openeras

  class LabelsController < Iox::ApplicationController

    before_filter :authenticate!
    
    def index
      q = Label.where('')
      if params[:query] && !params[:query].blank?
        q = q.where("name LIKE ?", "%#{params[:query]}%")
      end
      render json: { items: q.load }
    end

    def create
      if params[:name] && params[:name].size > 0
        @label = Label.new name: params[:name], type: params[:type], color: '#444'
        if @label.save
          flash.now.notice = t('saved', name: @label.name)
        else
          flash.now.alert = t('saving_failed', name: params[:name])
        end
      else
        flash.now.alert = t('invalid_params')
      end
      render json: { item: @label, success: flash[:alert].blank?, flash: flash }
    end

    def projects
      load_for ProjectLabel.where('')
    end

    def people
      load_for PersonLabel.where('')
    end

    def destroy
      if @label = Label.find_by_id( params[:id] )
        if @label.destroy
          flash.now.notice = t('deleted', name: @label.name)
        else
          flash.now.alert = t('deletion_failed', name: @label.name)
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { item: @label, success: params[:alert].blank?, flash: flash }
    end

    private

    def load_for( q )
      if params[:query] && !params[:query].blank?
        q = q.where("name LIKE ?", "%#{params[:query]}%")
      end
      if params[:parent_id] && !params[:parent_id].blank?
        q = q.where(parent_id: params[:parent_id])
      else
        q = q.where("parent_id IS NULL")
      end
      render json: { items: q.load }
    end
    
  end

end