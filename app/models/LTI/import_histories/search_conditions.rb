module LTI
  module ImportHistories
    class SearchConditions
      include ActiveModel::Model
      include ::SelectableAttr::Base

      attr_accessor :current_lms_user
      attr_accessor :page

      attr_accessor :operated_at_from
      attr_accessor :operated_time_at_from
      attr_accessor :operated_at_to
      attr_accessor :operated_time_at_to

      attr_accessor :sort_condition

      selectable_attr :import_type do
        entry 'LmsUserImport', :lms_user_imports, 'LMSユーザ'
      end

      def search

        admin_user = current_lms_user.admin_user

        import_histories = ::LTIImportHistory.all

        #インポート対象
        if self.import_type.present?
          import_histories = import_histories.where(target_type: self.import_type)
        end

        #操作日時(FROM)
        if self.operated_at_from.present?
          operated_time = self.operated_time_at_from.present? ? " #{self.operated_time_at_from}" : " 00:00:00"
          import_histories = import_histories.where("created_at >= ?", "#{self.operated_at_from}#{operated_time}")
        end

        #操作日時(TO)
        if self.operated_at_to.present?
          operated_time = self.operated_time_at_to.present? ? " #{self.operated_time_at_to}" : " 23:59:59"
          import_histories = import_histories.where("created_at <= ?", "#{self.operated_at_to}#{operated_time}")
        end

        # ソート設定
        if self.sort_condition.present?
          self.sort_condition.each do |k ,v|
            case k
            when :import_type then
              field_name = "target_type"
            when :imported_at then
              field_name = "created_at"
            end

            if v[:direction] == :desc
              import_histories = import_histories.order("#{field_name} desc")
            elsif v[:direction] == :asc
              import_histories = import_histories.order("#{field_name}")
            end
          end
        else
          import_histories = import_histories.order("created_at desc")
        end

        import_histories
      end
    end
  end
end