module Logic
  class LmsApiBaseLogic

    def self.debug_log(message)
      Rails.logger.info(message)
      puts message
    end

  end
end
