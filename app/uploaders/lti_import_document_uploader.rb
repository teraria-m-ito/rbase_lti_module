# frozen_string_literal: true

# 取込ファイル（個人情報を含む）は public 配下に置かず、URL から直接取得できないようにする
class LtiImportDocumentUploader < ::DocumentUploader
  def root
    ::Rails.root.to_s
  end

  def store_dir
    "private_uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    "private_uploads/tmp"
  end

  def extension_allowlist
    %w[xlsx]
  end
end
