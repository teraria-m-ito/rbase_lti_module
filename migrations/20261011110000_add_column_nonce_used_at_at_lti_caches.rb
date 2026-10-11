class AddColumnNonceUsedAtAtLtiCaches < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_caches, :nonce_used_at, :datetime, comment: "ナンス使用日時（LTI 起動で使用済み）"
  end
end
