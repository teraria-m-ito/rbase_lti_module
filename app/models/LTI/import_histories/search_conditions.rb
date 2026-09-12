module LTI
  module ImportHistories
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

      attr_accessor :sort_condition

      selectable_attr :import_type do
        entry 'LmsUserImport', :lms_user_imports, 'LMSユーザ', base: true
        entry 'LTIOrgImport', :lti_org_imports, '組織', base: true
      end

      validate :validate_operated_at_range

      def search
        import_histories = ::LTIImportHistory.all

        #インポート対象
        if self.import_type.present?
          import_histories = import_histories.where(target_type: self.import_type)
        end

        #操作日時(FROM)
        if operated_at_from.present?
          from = parse_operated_at(operated_at_from, legacy_time: operated_time_at_from)
          import_histories = import_histories.where("created_at >= ?", from) if from
        end

        #操作日時(TO)
        if operated_at_to.present?
          to = parse_operated_at(operated_at_to, legacy_time: operated_time_at_to, end_of_day: true)
          if to
            if operated_at_to.to_s.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\z/)
              import_histories = import_histories.where("created_at < ?", to + 1.minute)
            else
              import_histories = import_histories.where("created_at <= ?", to)
            end
          end
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

      private

      def validate_operated_at_range
        from = parse_operated_at(operated_at_from, legacy_time: operated_time_at_from)
        to = parse_operated_at(operated_at_to, legacy_time: operated_time_at_to, end_of_day: true)

        errors.add(:operated_at_from, :invalid) if operated_at_from.present? && from.nil?
        errors.add(:operated_at_to, :invalid) if operated_at_to.present? && to.nil?
        errors.add(:operated_at_to, :greater_than_or_equal_to, count: operated_at_from) if from && to && to < from
      end

      def parse_operated_at(value, legacy_time: nil, end_of_day: false)
        return nil if value.blank?

        raw = value.to_s
        if raw.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          time = legacy_time.presence || (end_of_day ? "23:59:59" : "00:00:00")
          raw = "#{raw} #{time}"
        end
        Time.zone.parse(raw)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end