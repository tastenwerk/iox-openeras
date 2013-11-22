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
      @query = @query.includes(:updater).references(:iox_users)

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
      render json: @project
    end

    def create
      @project = Project.new entry_params
      @layout = true
      if current_user.is_admin? && params[:with_user]
        @project.created_by = params[:with_user]
      else
        @project.created_by = current_user.id
      end

      if @project.save
        begin
          Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'created', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: program_entries_path(@project)
        rescue
        end

        flash.now.notice = t('project.created')
        @proceed_to_step = 1
        render template: 'iox/program_entries/edit'
      else
        flash.now.alert = t('project.failed_to_save')
        render template: 'iox/program_entries/new'
      end
    end

    def update
      if check_404_and_privileges
        @project.updated_by = current_user.id
        if @project.update entry_params

          Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'updated', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: program_entries_path(@project)

          flash.now.notice = t('project.saved')
        else
          flash.now.alert = t('project.failed_to_save')
        end
      else
        flash.now.alert = t('not_found')
      end
    end

    def finish
      if @project = Project.find_by_id( params[:id] )
        if @project.update params.require(:project).permit(:published, :others_can_change, :notify_me_on_change)
          flash.notice = t('project.saved')
        else
          flash.alert = t('project.failed_to_save')
        end
      else
        flash.alert = t('not_found')
      end
      redirect_to program_entries_path
    end

    #
    # publish a project
    #
    def publish
      if check_404_and_privileges
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

          Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: (@published ? 'published' : 'unpublished'), icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: program_entries_path(@project)

        else
          flash.now.alert = 'unknown error'
        end
      end
      render :json => { flash: flash, item: @project, success: !flash.notice.blank? }
    end

    def edit
      if @insufficient_rights = !check_404_and_privileges
        flash.now.alert = t('insufficient_rights_you_cannot_save')
      end
      @layout = (!params[:layout] || params[:layout] === 'true')
      render layout: @layout
    end

   def crew_of
      @project = Project.find_by_id( params[:id] )
      @crew = @project.project_people.includes(:person).references(:iox_people).order('iox_project_people.position','iox_people.lastname','iox_people.firstname').load
      json_crew = []
      @crew.each do |person|
        unless person.person
          person.destroy
          next
        end
        json_crew << person
      end
      render json: json_crew
    end

    def events_for
      @project = Project.find_by_id( params[:id] )
      events = []
      @program_entries = @project.events.includes(:venue,:festival).references(:iox_venues,:projects).order('iox_program_events.starts_at').load
      render json: @program_entries
    end

    def images_for
      if @project = Project.find_by_id( params[:id] )
        render json: @project.images.map{ |i| i.to_jq_upload('file') }
      else
        logger.error "program entry not found (#{params[:id]})"
        render json: []
      end
    end

    def festivals
      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        @query = "LOWER(title) LIKE '%#{filter}%'"
      end
      @festivals = Project.where(categories: 'fes').where( @query ).order(:title).load
      render json: @festivals
    end

    def upload_image
      if @project = Project.find_by_id( params[:id] )
        @image = @project.images.build(
          name: (params[:name].blank? ? params[:image][:file].original_filename : params[:name]),
          description: params[:description],
          copyright: params[:copyright]
          )
        @image.file = params[:image][:file]
        if @image.save
          flash.notice = t('program_file.uploaded', name: @image.name )
          render :json => { item: @image.to_jq_upload('file'), flash: flash }
        else
          logger.error "#{current_user.name} tried to upload #{@image.file.original_filename} #{@image.file.content_type}"
          render :json => {:errors => @image.errors}.to_json, :status => 500
        end
      else
        logger.error "program entry not found (#{params[:id]})"
      end
    end

    def download_image_from_url
      if @project = Project.find_by_id( params[:id] )
        extname = File.extname(params[:download_url])
        basename = File.basename(params[:download_url], extname)
        file = Tempfile.new([basename, extname])
        file.binmode
        open( params[:download_url] ) do |data|
          file.write data.read
        end
        file.rewind

        @image = @project.images.build(
          name: (params[:name].blank? ? basename : params[:name]),
          description: params[:description],
          copyright: params[:copyright]
          )
        @image.file = file
        if @image.save
          flash.notice = t('program_file.uploaded', name: @image.name )
          render :json => { item: @image.to_jq_upload('file'), flash: flash }
        else
          logger.error "#{current_user.name} tried to upload #{basename} #{file.content_type}"
          render :json => {:errors => @image.errors}.to_json, :status => 500
        end
      else
        logger.error "program entry not found (#{params[:id]})"
      end
    end

    def order_images
      if @project = Project.find_by_id( params[:id] )
        if params[:order]
          errors = 0
          params[:order].split(',').each_with_index do |img_id, pos|
            @image = @project.images.where( id: img_id.sub('image_','') ).first
            @image.position = pos
            errors += 1 unless @image.save
          end
          if errors == 0
            flash.now.notice = t('program_file.order_saved')
          else
            flash.now.alert = t('program_file.order_failed')
          end
        end
      else
        flash.now.alert = t('not_found');
      end
      render json: flash
    end

    def order_crew
      if @project = Project.find_by_id( params[:id] )
        if params[:order]
          errors = 0
          params[:order].split(',').each_with_index do |crew_id, pos|
            @pe_person = @project.project_people.where( id: crew_id.sub('crew_','') ).first
            @pe_person.position = pos
            errors += 1 unless @pe_person.save
          end
          if errors == 0
            flash.now.notice = t('project.order_saved')
          else
            flash.now.alert = t('project.order_failed')
          end
        end
      else
        flash.now.alert = t('not_found');
      end
      render json: flash
    end

    def destroy
      if check_404_and_privileges
        if @project.delete

        Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'deleted', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: program_entries_path(@project)

          flash.now.notice = t('project.deleted', name: @project.title, id: @project.id )
        else
          flash.now.alert = t('project.deletion_failed', name: @project.title)
        end
      end
      render json: { success: !flash[:notice].blank?, flash: flash }
    end

    def restore
      if check_404_and_privileges
        if @project.restore

          Iox::Activity.create! user_id: current_user.id, obj_name: @project.title, action: 'restored', icon_class: 'icon-calendar', obj_id: @project.id, obj_type: @project.class.name, obj_path: program_entries_path(@project)

          flash.now.notice = t('project.restored', name: @project.title)
        else
          flash.now.alert = t('project.failed_to_restore', name: @project.title)
        end
      end
    end

    private

    def entry_params
      params.require(:project).permit([
        :title, :subtitle,
        :description, :age,
        :duration, :ensemble_id,
        :categories, :url,
        :meta_keywords, :meta_description,
        :author, :coproduction,
        :others_can_change,
        :published,
        :cabaret_artist_ids, :author_ids,
        :youtube_url, :vimeo_url,
        :show_cabaret_artists_in_title, :has_breaks,
        :notify_me_on_change])
    end

    def redirect_if_no_rights
      if !current_user.is_admin?
        flash.alert = I18n.t('error.insufficient_rights')
        render json: { success: false, flash: flash }
        return false
      end
      true
    end

    def check_404_and_privileges(hard_check=false)
      @insufficient_rights = true
      unless @project = Project.unscoped.where( id: params[:id] ).first
        if request.xhr?
          flash.now.alert = t('not_found')
        else
          flash.alert = t('not_found')
          redirect_to ensembles_path
        end
        return false
      end

      if !current_user.is_admin? && @project.created_by != current_user.id && (!@project.others_can_change || hard_check)
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
  end
end