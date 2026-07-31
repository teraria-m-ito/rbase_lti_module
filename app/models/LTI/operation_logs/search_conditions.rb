module LTI
  module OperationLogs
    class SearchConditions
      include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
      include ActiveModel::Model
      include ::SelectableAttr::Base
    
      attr_accessor :current_lms_user
      attr_accessor :page

      attr_accessor :operated_at_from
      attr_accessor :operated_time_at_from
      attr_accessor :operated_at_to
      attr_accessor :operated_time_at_to

      attr_accessor :user_id
      attr_accessor :user_name
      attr_accessor :institution
      attr_accessor :department

      attr_accessor :sort_condition

      selectable_attr :form_type do
        ::LTIOperationLog.form_type_enum.each do |e|
          entry e.id, e.key, e.name
        end
      end

      selectable_attr :operation_div do
        ::LTIOperationLog.operation_div_enum.each do |e|
          entry e.id, e.key, e.name
        end
      end

      def search
      
        operation_logs = ::LTIOperationLog.all

        #操作日時(FROM)
        if self.operated_at_from.present?
          operated_time = self.operated_time_at_from.present? ? " #{self.operated_time_at_from}" : " 00:00:00"
          operation_logs = operation_logs.where("operated_at >= ?", "#{self.operated_at_from}#{operated_time}")
        end

        #操作日時(TO)
        if self.operated_at_to.present?
          operated_time = self.operated_time_at_to.present? ? " #{self.operated_time_at_to}" : " 23:59:59"
          operation_logs = operation_logs.where("operated_at <= ?", "#{self.operated_at_to}#{operated_time}")
        end

        #ユーザID
        operation_logs = operation_logs.where("user_id like ?", "#{self.user_id}%") if self.user_id.present?

        #ユーザ名
        operation_logs = operation_logs.where("user_name like ?", "%#{self.user_name}%") if self.user_name.present?

        #学部
        operation_logs = operation_logs.where(inst_org_id: self.institution) if self.institution.present?

        #学科
        operation_logs = operation_logs.where(dept_org_id: self.department) if self.department.present?

        #対象
        if self.form_type
          form_type_reflection = self.form_type.compact.include?(::LTI::OperationLogs::SearchConditions.form_type_id_by_key(:reflection))
          form_type_showcase = self.form_type.compact.include?(::LTI::OperationLogs::SearchConditions.form_type_id_by_key(:showcase))

          if form_type_reflection and form_type_showcase
          else
            operation_logs = operation_logs.where(form_type: ::LTI::OperationLogs::SearchConditions.form_type_id_by_key(:reflection)) if form_type_reflection
            operation_logs = operation_logs.where(form_type: ::LTI::OperationLogs::SearchConditions.form_type_id_by_key(:showcase)) if form_type_showcase
          end
        end

        #操作
        if self.operation_div
          operation_div_view = self.operation_div.compact.include?(::LTI::OperationLogs::SearchConditions.operation_div_id_by_key(:view))
          operation_div_created_or_updated = self.operation_div.compact.include?(::LTI::OperationLogs::SearchConditions.operation_div_id_by_key(:created_or_updated))
          operation_div_deleted = self.operation_div.compact.include?(::LTI::OperationLogs::SearchConditions.operation_div_id_by_key(:deleted))

          if operation_div_view and operation_div_created_or_updated and operation_div_deleted
          else
            operation_logs = operation_logs.where(operation_div: ::LTI::OperationLogs::SearchConditions.operation_div_id_by_key(:view)) if operation_div_view
            operation_logs = operation_logs.where(operation_div: ::LTI::OperationLogs::SearchConditions.operation_div_id_by_key(:created_or_updated)) if operation_div_created_or_updated
            operation_logs = operation_logs.where(operation_div: ::LTI::OperationLogs::SearchConditions.operation_div_id_by_key(:deleted)) if operation_div_deleted
          end
        end

        # ソート設定
        if self.sort_condition.present?
          self.sort_condition.each do |k ,v|
            case k
            when :operated_at then
              field_name = "operated_at"
            when :user_id then
              field_name = "user_id"
            when :user_name then
              field_name = "user_name"
            when :institution then
              field_name = "institution"
            when :department then
              field_name = "department"
            when :form_type then
              field_name = "form_type"
            when :operation_div then
              field_name = "operation_div"
            when :screen_name then
              field_name = "screen_name"
            end
            if v[:direction] == :desc
              operation_logs = operation_logs.order("#{field_name} desc")
            elsif v[:direction] == :asc
              operation_logs = operation_logs.order("#{field_name}")
            end
          end
        else
          operation_logs = operation_logs.order("created_at DESC")
        end

        operation_logs
      end
    end
  end
end