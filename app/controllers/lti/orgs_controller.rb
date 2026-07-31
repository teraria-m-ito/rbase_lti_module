module Lti
  class OrgsController < ::CustomUserApplicationController
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    respond_to :html

    before_action :set_lti_org, only: [:show, :edit, :update, :show, :destroy]
    before_action :set_inst_dept
    before_action :set_options, only: [:new, :create, :edit, :update, :show]
    def index
      @model_name = "LTI_orgs/sort_conditions"
      @sort_url = lti_orgs_path

      if params[:clear] == "true"
        session[:lti_orgs_search_conditions] = nil
        session[@model_name] = nil
      end

      @stimulus_params = {
      }.to_json

      if params[:sort_field_name]
        @sort_field_name = params[:sort_field_name].nil? ? nil : params[:sort_field_name].to_sym
        sort_condition = set_sort_field
      end
      
      #ソートを行うので、検索条件は非表示で対応
      if params[:lti_orgs_search_conditions]
        @condition = ::LTI::Orgs::SearchConditions.new(search_condition_params)
        return render 'index' unless @condition.valid?

        unless sort_condition
          session[@model_name] = nil
        end
        @condition.sort_condition = sort_condition
        @condition.page = params[:page] if params[:page].present?

        session[:lti_orgs_search_conditions] = @condition
        @lti_orgs = @condition.search.page(@condition.page)
      else
        if session[:lti_orgs_search_conditions]
          @condition = session[:lti_orgs_search_conditions]
          @condition.page = params[:page] if params[:page].present?
          @condition.sort_condition = sort_condition if sort_condition
          @lti_orgs = @condition.search.page(@condition.page)
        else
          @condition = ::LTI::Orgs::SearchConditions.new
          @condition.sort_condition = sort_condition if sort_condition
          @condition.page = params[:page] if params[:page].present?
          session[:lti_orgs_search_conditions] = @condition
          @lti_orgs = @condition.search.page(@condition.page)
        end
      end
      
      #ソート場合、turbo_frame_tagの更新を行う
      if @sort_field_name
        render turbo_stream: [
          turbo_stream.replace("entry-turbo-org_search_results", partial: 'lti/orgs/search_results'),
        ]
      elsif params[:destroyed] == "true"
        render turbo_stream: [
          turbo_stream.replace("entry-turbo-message", partial: 'common/message'),
          turbo_stream.replace("entry-turbo-org_search_results", partial: 'lti/orgs/search_results'),
        ]
      else
        render :index
      end
            
    end
    
    def new
      @lti_org = ::LTIOrg.new
    end
    
    def edit
    end
    
    
    def create
      @lti_org = ::LTIOrg.new(lti_org_params)
      @lti_org.current_admin_user = current_admin_user
      if @lti_org.save_org
        flash[:notice] = t("views.common.create_complete_message")
        redirect_to lti_orgs_path, status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      ActiveRecord::Base.transaction do
        @lti_org.assign_attributes(lti_org_params)
        @lti_org.current_admin_user = current_admin_user
        if @lti_org.save_org
          flash[:notice] = t("views.common.update_complete_message")
          respond_with(@lti_org, location: lti_orgs_path)
        else
          render :edit, status: :unprocessable_entity
        end
      end
    end
    
    def show
      
    end
    
    def destroy
      @lti_org.current_admin_user = current_admin_user
      flash[:notice] = t("views.common.destroy_complete_message") if @lti_org.destroy
      redirect_to lti_orgs_path(destroyed: true), status: :see_other
      # respond_with(@lti_org, location: lti_orgs_path)
    end

    private

    def set_lti_org
      @lti_org = ::LTIOrg.find(params[:id])
    end
    
    def set_inst_dept
      @parent_orgs = ::LTIOrg.where("parent_org_id IS NOT NULL").all
      @institutions = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:institution)).order(:org_cd).all
      @departments = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:department)).order(:parent_org_id).order(:org_cd).all
      @courses = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:course)).order(:org_cd).all
    end

    def set_options
      @org_div = LTIOrg.org_div_options

      #大学を定義済である場合は、大学を除外する
      root_id = ::LTIOrg.org_div_id_by_key(:root)
      root_org = ::LTIOrg.where(org_div: root_id).first
      if root_org
        @org_div = @org_div.select{|x| x[1] != root_id}
      end

      @parent_org_id = ::LTIOrg.dependents_list.map{|x| [x.org_name, x.id]}

      #大学を定義済である場合は、大学を除外する
      # if root_org
      #   @parent_org_id = @parent_org_id.select{|x| x[1] != root_org.id}
      # end

      #自身を除外する
      if @lti_org
        @parent_org_id = @parent_org_id.select{|x| x[1] != @lti_org.id}
      end
    end

    def search_condition_params
      params.require(:lti_orgs_search_conditions).permit! #(:issue_type_name, :issue_type_class)
    end
    
    def lti_org_params
      params.require(:lti_org).permit! #(:issue_type_name, :issue_type_class)
    end
  end
end
