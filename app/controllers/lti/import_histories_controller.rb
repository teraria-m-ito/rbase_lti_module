module Lti
  class ImportHistoriesController < ::Lti::AdminBasesController
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    respond_to :html

    before_action :set_lti_import_history, only: [:show]
    
    after_action :allow_iframe

    def index
      @model_name = "LTI_import_histories/sort_conditions"
      @sort_url = lti_import_histories_path

      if params[:clear] == "true"
        session[:lti_import_histories_search_conditions] = nil
        session[@model_name] = nil
      end

      @stimulus_params = {
      }.to_json

      if params[:sort_field_name]
        @sort_field_name = params[:sort_field_name].nil? ? nil : params[:sort_field_name].to_sym
        sort_condition = set_sort_field
      end

      if params[:lti_import_histories_search_conditions]
        @condition = ::LTI::ImportHistories::SearchConditions.new(search_condition_params)
        return render 'index' unless @condition.valid?
        @condition.current_lms_user = current_lms_user

        unless sort_condition
          session[@model_name] = nil
        end

        @condition.sort_condition = sort_condition
        @condition.page = params[:page] if params[:page].present?

        session[:lti_import_histories_search_conditions] = @condition
        @lti_import_histories = @condition.search.page(@condition.page)
      else
        if session[:lti_import_histories_search_conditions]
          @condition = session[:lti_import_histories_search_conditions]
          @condition.current_lms_user = current_lms_user
          @condition.page = params[:page] if params[:page].present?
          @condition.sort_condition = sort_condition if sort_condition
          @lti_import_histories = @condition.search.page(@condition.page)
        else
          @condition = ::LTI::ImportHistories::SearchConditions.new
          @condition.current_lms_user = current_lms_user
          @condition.page = params[:page] if params[:page].present?
          @condition.sort_condition = sort_condition if sort_condition
          session[:lti_import_histories_search_conditions] = @condition
          @lti_import_histories = @condition.search.page(@condition.page)
        end
      end
      #ソート場合、turbo_frame_tagの更新を行う
      if @sort_field_name
        render turbo_stream: [
          turbo_stream.replace("entry-turbo-import_histories_search_results", partial: 'lti/import_histories/search_results'),
        ]
      else
        render :index
      end
    end

    def show
      @lti_import_history_errors = @lti_import_history.import_errors
    end

    private
    def set_lti_import_history
      @lti_import_history = ::LTIImportHistory.find(params[:id].to_i)
    end

    def search_condition_params
      params.require(:lti_import_histories_search_conditions).permit!
    end

  end
end
