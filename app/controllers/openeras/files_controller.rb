module Openeras

  class FilesController < ApplicationController

    before_filter :authenticate!

    def index
      @project = Project.find_by_id( params[:project_id] )
      @files = @project.files.order(@order)
      render json: @files
    end

    def create
      @project = Project.find_by_id( params[:project_id] )

      @file = @project.files.build name: params[:file].original_filename
      @file.file = params[:file]

      @file.creator = current_user
      @file.updater = current_user

      if @file.save
        render json: { flash: flash, success: flash[:alert].blank?, item: @file }
      else
        render :json => [{:error => "custom_failure"}], :status => 304
      end
    end

    def edit
      @file = Openeras::File.find_by_id( params[:id] )
      render layout: false
    end

    def update
      if @file = Openeras::File.find_by_id( params[:id] )
        @file.updater = current_user
        if @file.update file_params
          flash.notice = t('openeras.file.saved', name: @file.name )
        else
          logger.error "FILE could not be saved: #{@file.errors.full_messages}"
          flash.alert = t('openeras.file.saving_failed', name: @file.name, error: @file.errors.full_messages.inspect )
        end
      else
        notify_404
      end
      render json: { flash: flash, success: flash[:alert].blank?, item: @file }
    end

    def coords
      if @file = Openeras::File.find_by_id( params[:id] )
        @file.updater = current_user
        @file.set_offset_styles( params[:size], params[:x], params[:y] )
        if @file.save
          flash.now.notice = t('openeras.file.coords_saved', name: @file.name, size: params[:size])
        else
          flash.now.alert = t('openeras.file.coords_saving_failed', name: @file.name, size: params[:size])
        end
      else
        notify_404
      end
      render json: { flash: flash, success: flash[:alert].blank?, item: @file }
    end

    def destroy
      success = false
      if @file = Openeras::File.find_by_id( params[:id] )
        if @file.destroy
          flash.now.notice = t('deleted')
          success = true
          flash.now.notice = t('openeras.file.deleted', name: @file.name)
        else
          flash.now.alert = t('deletion_failed')
        end
      else
        notify_404
      end
      render json: { flash: flash, success: success, item: @file }
    end

    private

    def file_params
      params.require(:file).permit(:name, :description, :copyright)
    end

  end

end