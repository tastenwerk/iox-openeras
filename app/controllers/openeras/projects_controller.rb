module Openeras
  class ProjectsController < Iox::ApplicationController

    before_filter :authenticate!
    layout 'iox/application'

    def index

      return unless request.xhr?

      @query = Project.where('')
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        if filter.match(/^[\d]*$/)
          @query = @query.where('project.id' => filter)
        elsif filter.include?('#')
          @query = @query.where( 'openeras_labels.id' => filter.split('#')[0] )
        else
          @query = @query.where "LOWER(title) LIKE ? OR LOWER(subtitle) LIKE ? OR LOWER(openeras_projects.meta_keywords) LIKE ?", 
                                "%#{filter}",
                                "%#{filter}",
                                "%#{filter}"
        end
      end

      # conflict_id
      if params[:conflict_id] && !params[:conflict_id].blank?
        @query = @query.where "openeras_projects.conflict_id" => params[:conflict_id]
      end

      # starts_at
      if params[:starts_at] && !params[:starts_at].blank?
        begin
          @query = @query.where "openeras_projects.starts_at >= ?", Time.parse( params[:starts_at] )
        rescue => e
          if e.message.include? "no time information"
            @query = @query.where "openeras_projects.starts_at >= ?", Time.now
          else
            raise e
          end
        end
      end

      # published?
      if params[:published] && !params[:published].blank?
        @query = @query.where "openeras_projects.published" => (params[:published] == 'true')
      end

      # setup full query
      @query = @query.includes(:updater,:labels).references(:iox_users, :openeras_labels)

      @total_items = @query.count

      @page = (params[:skip] || 0).to_i
      @page = @page / params[:pageSize].to_i if @page > 0 && params[:pageSize]
      @limit = (params[:take] || 20).to_i
      @total_pages = @total_items/@limit
      @total_pages += 1 if ((@total_items % @limit) > 0)

      @order = 'openeras_projects.created_at DESC'
      if params[:sort]
        sort = params[:sort]['0'][:field]
        unless sort.blank?
          sort = "openeras_projects.#{sort}" if sort.match(/id|created_at|updated_at|starts_at|ends_at/)
          sort = "LOWER(title)" if sort === 'title'
          sort = "LOWER(iox_users.username)" if sort == 'updater_name'
          @order = "#{sort} #{params[:sort]['0'][:dir]}"
        end
      end

      @projects = @query.limit( @limit ).offset( (@page) * @limit ).order(@order).load

      render json: { items: @projects, total: @total_items, order: @order }

    end

    def new
      @project = Project.new init_label_id: params[:init_label_id]
      Rails.configuration.iox.available_langs.each do |lang|
        @project.translations.build locale: lang, title: ''
      end
      render json: @project
    end

    def create
      @project = Project.new project_params
      @project.set_creator_and_updater( current_user )
      if @project.save

        @project.update_label_ids
           
        begin
          Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'created', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: projects_path(@project)
        rescue
        end
        flash.now.notice = t('created', name: @project.title)
      else
        puts @project.errors.inspect
        flash.now.alert = t('creation_failed')
      end
      render json: { item: @project, flash: flash, success: flash[:alert].blank? }
    end

    def update
      if @project = get_project
        if can_modify?( @project )
          @project.set_creator_and_updater( current_user )
          @project.update project_params
          if @project.save

            @project.update_label_ids
            
            trans = @project.translations.where(locale: params[:project][:translation][:locale]).first
            puts "trans: #{trans.locale if trans}"
            if trans
              trans.update translation_params
            else
              @project.translations.create translation_params
            end

            Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'updated', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: projects_path(@project)

            flash.now.notice = t('saved', name: @project.title)
          else
            flash.now.alert = t('saving_failed', name: @project.title)
          end
        else
          flash.now.alert('insufficient_rights')
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { item: @project, flash: flash, success: flash[:alert].blank? }
    end

    # update a given translation
    def translation
      if @project = get_project
        if can_modify?( @project )
            
          trans = @project.translations.where(locale: params[:project][:translation][:locale]).first
          puts "trans: #{trans.locale if trans}"
          if trans
            puts "updateing #{translation_params.inspect}"
            unless trans.update translation_params
              flash.now.alert('saving_failed', name: @project.title)
            end
          else
            unless @project.translations.create translation_params
              flash.now.alert('saving_failed', name: @project.title)
            end
          end
        else
          flash.now.alert('insufficient_rights')
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { item: @project, flash: flash, success: flash[:alert].blank? }
    end

    #
    # publish a project
    #
    def publish
      if @project = get_project
        if can_modify?( @project )
          if params[:publish] == "true"
            @project.published = true
          else
            @project.published = false
          end
          if @project.save
            @published = false
            if @project.published?
              @published = true
              flash.now.notice = t('project.has_been_published', name: @project.title)
            else
              flash.now.notice = t('project.has_been_unpublished', name: @project.title)
            end

            Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: (@published ? 'published' : 'unpublished'), icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: projects_path(@project)

          else
            flash.now.alert = 'unknown error'
          end
        end
      else
        flash.now.alert = t('not_found')
      end
      render :json => { flash: flash, item: @project, success: !flash.notice.blank? }
    end

    def destroy
      if @project = get_project
        if can_modify?( @project )
          if @project.delete
            Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'deleted', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: projects_path(@project)
            flash.now.notice = t('project.deleted', name: @project.title, id: @project.id )
          else
            flash.now.alert = t('project.deletion_failed', name: @project.title)
          end
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { item: @project, success: !flash[:notice].blank?, flash: flash }
    end

    def restore
      if @project = get_project
        if can_modify?( @project )
          if @project.restore
            Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'restored', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: projects_path(@project)
            flash.now.notice = t('project.restored', name: @project.title)
          else
            flash.now.alert = t('project.failed_to_restore', name: @project.title)
          end
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { item: @project, success: !flash[:notice].blank?, flash: flash }
    end

    private

    def get_project
      Project.find_by_id( params[:id] )
    end

    def project_params
      params.require(:project).permit(
        :title, 
        :subtitle,
        :age,
        :duration,
        :author, 
        :published,
        :authors,
        :youtube_url, 
        :vimeo_url,
        :has_breaks,
        :label_ids => []
      )
    end

    def translation_params
      params.require(:project).require(:translation).permit(
        :title,
        :subtitle,
        :meta_keywords,
        :meta_description,
        :content,
        :locale
      )
    end
  end
end