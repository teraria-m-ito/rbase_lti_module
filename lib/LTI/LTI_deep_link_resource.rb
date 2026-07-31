module LTI
  class LTIDeepLinkResource
    @type = nil
    @title = nil
    @url = nil
    @lineitem = nil
    @custom_params = nil
    @target = nil
    
    def initialize
      @type = 'ltiResourceLink'
      @custom_params = {}
    end
    
    def self.instance
      ::LTI::LTIDeepLinkResource.new
    end

    def get_type
      @type
    end
    
    def set_type(value)
      @type = value
      
      self
    end

    def get_title
      @title
    end
    
    def set_title(value)
      @title =  value
      
      self
    end

    def get_url
      @url
    end
    
    def set_url(value)
      @url = value
      
      self
    end

    def get_lineitem
      @lineitem
    end
    
    def set_lineitem(value)
      @lineitem = value
      
      self
    end
    
    def get_custom_params
      @custom_params
    end
    
    def set_custom_params(value)
      @custom_params = value
      
      self
    end

    def get_target
      @target
    end
    
    def set_target(value)
      @target = value
      
      self
    end

    def __to_array
      resource = {
        type: @type
      }

      if @title.present? or @url.present? or @custom_params.present? or @target.present?
        resource = {
          type: @type,
          presentation: {}
        }

        if @title.present?
          resource[:title] = @title
        end
        if @url.present?
          resource[:url] = @url
        end
        if @target.present?
          resource[:presentation] = {}
          resource[:presentation][:documentTarget] = @target
        end
        if @custom_params.present?
          resource[:custom] = @custom_params
        end
      end
      
      if @lineitem
        resource[:lineItem] = {
          scoreMaximum: @lineitem.get_score_maximum,
          label: @lineitem.get_label
        }
      end
      Rails.logger.info("[deeplink]__to_array:#{resource}")
      resource
    end
  end
end