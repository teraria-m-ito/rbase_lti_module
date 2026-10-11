module Logic
  class LmsApiBaseLogic

    # トークン等を含むため標準出力には出さず、ログファイルにのみ記録する
    def self.debug_log(message)
      Rails.logger.info(message)
    end

  end
end
