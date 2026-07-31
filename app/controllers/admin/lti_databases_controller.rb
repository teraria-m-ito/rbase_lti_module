module Admin
  class LtiDatabasesController < CustomAdminApplicationController
    before_action :set_lti_database, only: [:show, :edit, :update, :destroy]
    before_action :setup_values, only: [:index, :new, :create, :edit, :update, :show]

    respond_to :html
    def index
      if params[:lti_databases_search_conditions]
        @condition = LTIDatabases::SearchConditions.new(search_condition_params)
        @condition.sites = Array(@condition.sites).map(&:to_s)
        return render 'index' unless @condition.valid?
        @condition.current_admin_user = current_admin_user
        session[:lti_databases_search_conditions] = @condition
        
        @lti_databases = @condition.search.page(params[:page])
      else
        if session[:lti_databases_search_conditions]
          @condition = session[:lti_databases_search_conditions]
          @condition.current_admin_user = current_admin_user
          @lti_databases = @condition.search.page(params[:page])
        else
          @condition = LTIDatabases::SearchConditions.new
          @condition.current_admin_user = current_admin_user
          @lti_databases = @condition.search.page(params[:page])
        end
      end
    end

    def show
      respond_with(@lti_database)
    end

    def new
      @lti_database = LTIDatabase.new
      @stimulus_params = {
        url1: button_update_pem_admin_lti_databases_path,
        url2: button_update_kid_admin_lti_databases_path,
        update_confirm_message: I18n.t(:"views.common.update_confirm_message"),
        build_confirm_message: I18n.t(:"views.common.build_confirm_message")
      }.to_json
      respond_with(@lti_database)
    end

    def edit
      @stimulus_params = {
        url1: button_update_pem_admin_lti_databases_path,
        url2: button_update_kid_admin_lti_databases_path,
        update_confirm_message: I18n.t(:"views.common.update_confirm_message"),
        build_confirm_message: I18n.t(:"views.common.build_confirm_message")
      }.to_json
    end

    def create
      @lti_database = LTIDatabase.new(lti_database_params)

      if @lti_database.save
        flash[:notice] = t("views.common.create_complete_message")
        respond_with(@lti_database, location: admin_lti_databases_url)
      else
        @stimulus_params = {
          url1: button_update_pem_admin_lti_databases_path,
          url2: button_update_kid_admin_lti_databases_path,
          update_confirm_message: I18n.t(:"views.common.update_confirm_message"),
          build_confirm_message: I18n.t(:"views.common.build_confirm_message")
        }.to_json
        render :new, status: :unprocessable_entity
      end
    end
    def update
      ActiveRecord::Base.transaction do
        @lti_database.assign_attributes(lti_database_params)
        if @lti_database.save
          flash[:notice] = t("views.common.update_complete_message")
          respond_with(@lti_database, location: admin_lti_databases_url)
        else
          @stimulus_params = {
            url1: button_update_pem_admin_lti_databases_path,
            url2: button_update_kid_admin_lti_databases_path,
            update_confirm_message: I18n.t(:"views.common.update_confirm_message"),
            build_confirm_message: I18n.t(:"views.common.build_confirm_message")
          }.to_json
          render :edit, status: :unprocessable_entity
        end
      end
    end

    def destroy
      flash[:notice] = t("views.common.destroy_complete_message") if @lti_database.destroy
      respond_with(@lti_database, location: admin_lti_databases_url)
    end

    desc :auth_as => :index, :display_name => 'admin/lti_databases/button_update_pem'
    def button_update_pem
      pem, pub_pem = ::LTIDatabase.create_pem
      result = {
        pem: pem,
        pub_pem: pub_pem
      }
      render json: result
    end

    desc :auth_as => :index, :display_name => 'admin/lti_databases/button_update_pem'
    def button_update_kid
      kid = ::LTIDatabase.create_kid
      result = {
        kid: kid
      }
      render json: result
    end

    private
    def setup_values
      @sites = current_admin_user.sites.all
    end
    
    def set_lti_database
      @lti_database = LTIDatabase.find(params[:id])
    end

    def search_condition_params
      params[:lti_databases_search_conditions][:sites].to_a.reject!{|x|x.blank?}
      params.require(:lti_databases_search_conditions).permit!
    end
    
    def lti_database_params
      params.require(:lti_database).permit!
    end
    
  end
end
