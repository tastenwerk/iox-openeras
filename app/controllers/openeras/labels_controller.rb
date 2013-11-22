require_dependency "iox/application_controller"

module Openeras

  class LabelsController < Iox::ApplicationController

    def create
      if params[:name] && params[:name].size > 0
        @label = Label.new name: params[:name], category: params[:category]
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

    def project_labels
      load_for(:project)
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

    def load_for( category )
      q = Label.where(category: category)
      render json: { items: q.load }
    end
    
  end

end