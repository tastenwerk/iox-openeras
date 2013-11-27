module Openeras
  class EventsController < Iox::ApplicationController

    before_filter :authenticate!

    def index
      @project = Project.find_by_id params[:project_id]
      @events = @project.events
      render json: { items: @events, total: @events.size }
    end

    def create
      @event = Event.new event_params
      if @event.save
        flash.now.notice = t('openeras.event.saved', starts: l(@event.starts_at, format: :short), venue: (@event.venue ? @event.venue.name : '') )
      else
        flash.now.alert = t('openeras.event.saving_failed')
      end
      render json: { flash: flash, item: @event, success: flash[:alert].blank? }
    end

    def new
      @event = Event.new project_id: params[:project_id],
                         starts_at: Time.now.strftime('%Y-%m-%d 20:00'),
                         ends_at: Time.now.strftime('%Y-%m-%d 22:00'),
                         available_seats: 80
      render layout: false
    end

    def edit
      unless @event = Event.find_by_id( params[:id] )
        return render text: '', status: 404
      end
      render layout: false
    end

    def update
      @event = Event.find_by_id params[:id]
      if @event.update event_params
        flash.now.notice = t('openeras.event.saved', starts: (@event.starts_at ? l(@event.starts_at, format: :short) : ''), venue: (@event.venue ? @event.venue.name : '') )
      else
        flash.now.alert = t('openeras.event.saving_failed')
      end
      render json: { flash: flash, success: flash[:alert].blank?, item: @event }
    end

    def destroy
      if @event = Event.find_by_id( params[:id] )
        if @event.destroy
          flash.now.notice = t('openeras.event.deleted', starts: l(@event.starts_at, format: :short), venue: (@event.venue ? @event.venue.name : ''))
        else
          flash.now.alert = t('openeras.event.deletion_failed')
        end
      else
        notify_404
      end
      render json: { flash: flash, item: @event, success: flash[:alert].blank? }
    end

    private

    def event_params
      params.require(:event).permit(
        :starts_at, 
        :ends_at, 
        :all_day, 
        :event_type, 
        :venue_id,
        :additional_note, 
        :project_id,
        :available_seats,
        :description)
    end

  end
end