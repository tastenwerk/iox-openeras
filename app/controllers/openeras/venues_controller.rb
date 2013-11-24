require_dependency "iox/application_controller"

module Openeras
  class VenuesController < Iox::ApplicationController

    before_filter :authenticate!

    def index

      q = Venue.where('')
      if params[:query] && !params[:query].blank?
        q = q.where("name LIKE ?", "%#{params[:query]}%")
      end
      render json: { items: q.load }

    end

    def new
      @obj = Venue.new country: 'at', name: (params[:name] || '')
      @hidden_fields = [:country]
      render template: 'iox/common/new_form', layout: false
    end

    def create
      @venue = Venue.new venue_params
      @venue.set_creator_and_updater( current_user )
      if @venue.save

        Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'created', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

        flash.now.notice = t('openeras.venue.saved', name: @venue.name)
        if request.xhr?
          @remote = true
        else
          redirect_to edit_venue_path( @venue )
        end
      else
        flash.now.alert = t('openeras.venue.saving_failed')
      end
      render json: { item: @venue, flash: flash, success: flash[:alert].blank? }
    end

    def edit
      check_404_and_privileges
      @layout = (!params[:layout] || params[:layout] === 'true')
      render layout: @layout
    end

    def update
      if check_404_and_privileges
        @venue.updater = current_user
        @venue.attributes = venue_params
        if @venue.save
          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'updated', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('openeras.venue.saved', name: @venue.name)
          redirect_to edit_venue_path( @venue ) unless request.xhr?
        else
          flash.now.alert = t('openeras.venue.saving_failed')
        end
      else
        redirect_to venues_path unless request.xhr?
      end
      render json: { item: @venue, flash: flash, success: flash[:alert].blank? }
    end

    def destroy
      if check_404_and_privileges true
        if @venue && @venue.delete

          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'deleted', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('openeras.venue.deleted', name: @venue.name, id: @venue.id)
        else
          flash.now.alert = t('openeras.venue.deletion_failed', name: @venue.name)
        end
      end
      render json: { success: !flash.alert, flash: flash }
    end

    def restore
      if check_404_and_privileges

        if @venue.restore

          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'restored', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('openeras.venue.restored', name: @venue.name)
        else
          flash.now.alert = t('openeras.venue.failed_to_restore', name: @venue.name)
        end
      end
    end


    private

    def check_404_and_privileges(hard_check=false)
      @insufficient_rights = true
      unless @venue = Venue.unscoped.where( id: params[:id] ).first
        if request.xhr?
          flash.now.alert = t('not_found')
        else
          flash.alert = t('not_found')
          redirect_to ensembles_path
        end
        return false
      end
      if !current_user.is_admin? && @venue.created_by != current_user.id && (!@venue.others_can_change || hard_check)
        if request.xhr?
          flash.now.alert = t('insufficient_rights_you_cannot_save')
        else
          flash.alert = t('insufficient_rights_you_cannot_save')
          redirect_to ensembles_path
        end
        return false
      end
      @insufficient_rights = false
      true
    end

    def venue_params
      params.require(:venue).permit([:email, :name, :zip, :city, :street, :url, :description, :country, :lat, :lng, :phone, :tickets_url, :facebook_url, :twitter_url, :youtube_url, :google_plus_url, :notify_me_on_change, :others_can_change, :archived])
    end

  end
end