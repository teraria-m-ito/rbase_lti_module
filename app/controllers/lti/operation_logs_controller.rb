module Lti
  class OperationLogsController < ::Lti::AdminBasesController
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    respond_to :html
    
    after_action :allow_iframe
    before_action :set_inst_dept

    def index
      @model_name = "LTI_operation_logs/sort_conditions"
      @sort_url = lti_operation_logs_path

      if params[:clear] == "true"
        session[:lti_operation_logs_search_conditions] = nil
        session[@model_name] = nil
      end

      @stimulus_params = {
      }.to_json

      if params[:sort_field_name]
        @sort_field_name = params[:sort_field_name].nil? ? nil : params[:sort_field_name].to_sym
        sort_condition = set_sort_field
      end
      
      #ソートを行うので、検索条件は非表示で対応
      if params[:lti_operation_logs_search_conditions]
        @condition = ::LTI::OperationLogs::SearchConditions.new(search_condition_params)
        return render 'index' unless @condition.valid?
        @condition.current_lms_user = current_lms_user

        unless sort_condition
          session[@model_name] = nil
        end
        @condition.sort_condition = sort_condition
        @condition.page = params[:page] if params[:page].present?

        session[:lti_operation_logs_search_conditions] = @condition
        @lti_operation_logs = @condition.search.page(@condition.page)
      else
        if session[:lti_operation_logs_search_conditions]
          @condition = session[:lti_operation_logs_search_conditions]
          @condition.current_lms_user = current_lms_user
          @condition.page = params[:page] if params[:page].present?
          @condition.sort_condition = sort_condition if sort_condition
          @lti_operation_logs = @condition.search.page(@condition.page)
        else
          @condition = ::LTI::OperationLogs::SearchConditions.new
          @condition.current_lms_user = current_lms_user
          @condition.sort_condition = sort_condition if sort_condition
          session[:lti_operation_logs_search_conditions] = @condition
          @lti_operation_logs = @condition.search.page(@condition.page)
        end
      end
      #ソート場合、turbo_frame_tagの更新を行う
      if @sort_field_name
        render_turbo_stream
      elsif params[:destroyed] == "true"
        render_turbo_stream_destroyed
      else
        render_index
      end
    end

    private
    def render_turbo_stream
      render turbo_stream: [
        turbo_stream.replace("entry-turbo-operation_log_search_results", partial: 'lti/operation_logs/search_results'),
      ]
    end

    def render_turbo_stream_destroyed
      render turbo_stream: [
        turbo_stream.replace("entry-turbo-message", partial: 'common/message'),
        turbo_stream.replace("entry-turbo-operation_log_search_results", partial: 'lti/operation_logs/search_results'),
      ]
    end

    def render_index
      render :index
    end

    def set_inst_dept
      @institutions = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:institution)).order(:org_cd).all
      @departments = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:department)).order(:org_cd).all
      @courses = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:course)).order(:org_cd).all
    end

    def search_condition_params
      params.require(:lti_operation_logs_search_conditions).permit! #(:issue_type_name, :issue_type_class)
    end
  end
end
