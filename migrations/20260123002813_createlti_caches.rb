class CreateltiCaches < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_caches, comment: "LTIキャッシュ" do |t|
      t.string :launch_id, index: true, comment: "起動ID"
      t.string :nonce, index: true, comment: "ナンス値"
      t.text :data, comment: "キャッシュデータ"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
