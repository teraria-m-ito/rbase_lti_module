# -*- coding: utf-8 -*-
require 'rake'

module RbaseLtiModule
  module SystemSettingExt
    extend ActiveSupport::Concern
    include ::ActiveModel::Validations

    def self.included(mod)
      mod.extend(ClassMethods)
      mod.module_eval do
      end
    end

    module ClassMethods
      # editable_divのselectable_attrをプラグインで拡張します
      def added_entries_for_setting_category_div_with_rbase_lti_module(mod)
        added_entries_for_setting_category_div_without_rbase_lti_module(mod)
        mod.entry 'CLTI', :lms_setting, 'LTI設定'
      end
      def added_entries_for_setting_div_with_rbase_lti_module(mod)
        added_entries_for_setting_div_without_rbase_lti_module(mod)
        mod.entry 'CLTI01', :default_role_div    , 'デフォルト権限設定'    , required: true, category: :lms_setting, input_type: :string, hint: <<-"END_OF_HINT" do
      ※ LMSからログインする場合に、ユーザ未作成の場合に設定するデフォルトロールを権限略称で指定します。
      入力例：
      member
      END_OF_HINT
        end
      #   mod.entry 'CLTI002', :api_token    , 'APIトークン'    , required: true, category: :lms_setting, input_type: :string, reload: true, hint: <<-"END_OF_HINT" do
      # ※　APIの認証となるトークンを登録します。
      # END_OF_HINT
      #   end
        mod.entry 'CLTI003', :lms_url    , 'LMSのURL'    , required: true, category: :lms_setting, input_type: :string, reload: true, hint: <<-"END_OF_HINT" do
      ※　リクエスト元のURLであるLMSのURLを指定します。
      END_OF_HINT
        end
        mod.entry 'CLTI004', :moodle_api_wstoken    , 'MOODLE用APIトークン'    , required: true, category: :lms_setting, input_type: :string, reload: true, hint: <<-"END_OF_HINT" do
      ※　MOODLE用APIトークンで指定します。
      abcdefgh123456789
      END_OF_HINT
        end
        mod.entry 'CLTI005', :lms_types    , 'LMSタイプ変換表'    , required: true, category: :lms_setting, input_type: :string, hint: <<-"END_OF_HINT" do
      ※ LMSタイプ変換表を設定します。
      　　この定義は、サイト１の設定がすべてのサイトに有効になります。
      入力例：
      　　https：//moodle.example.com|MOODLE
      　　https：//canvas.instructure.com|CANVAS
      END_OF_HINT
        end
        mod.entry 'CLTI006', :lms_field_names    , 'LMSカスタムフィールド変換表'    , required: true, category: :lms_setting, input_type: :string, hint: <<-"END_OF_HINT" do
      ※ LMSカスタムフィールド変換表を設定します。
      LMSでの名称|LTIツールでの名称
      で設定します。
      入力例：
      　　enteringyear|entering_year
      END_OF_HINT
        end
        mod.entry 'CLTI007', :top_page_content    , 'トップページ表示コンテンツ'    , required: true, category: :lms_setting, input_type: :string, hint: <<-"END_OF_HINT" do
      ※ トップページに表示するコンテンツを定義します。
      入力例：
      <h2>マネージャ向けお知らせ</h2>
      <p>
        ここにマネージャ用のお知らせを記載します。
      </p>
      END_OF_HINT
        end
      end
    end
  end
end
# rubocop:disable Style/For
