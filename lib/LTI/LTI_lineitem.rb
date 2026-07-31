module LTI
  class LTILineitem
    @id = nil
    @score_maximum = nil
    @label = nil
    @resource_id = nil
    @tag = nil
    @start_date_time = nil
    @end_date_time = nil
    
    def initialize(lineitem = nil)
      return if lineitem.nil?
      
      @id = lineitem['id']
      @score_maximum = lineitem['scoreMaximum']
      @label = lineitem['label']
      @resource_id = lineitem['resourceId']
      @tag = lineitem['tag']
      @start_date_time = lineitem['startDateTime']
      @end_date_time = lineitem['endDateTime']
    end

    def self.instance
      ::LTI::LTILineitem.new
    end
    
    def get_id
      @id
    end

    def set_id(value)
      @id = value
      self
    end

    def get_label
      @label
    end
    
    def set_label(value)
      @label = value
      self
    end

    def get_score_maximum
      @score_maximum
    end
    
    def set_score_maximum(value)
      @score_maximum = value
      self
    end

    def get_resource_id
      @resource_id
    end
    
    def set_resource_id(value)
      @resource_id = value
      self
    end
    
    def get_tag
      @tag
    end
    
    def set_tag(value)
      @tag = value
      
      self
    end

    def get_start_date_time
      @start_date_time
    end
    
    def set_start_date_time(value)
      @start_date_time = value

      self
    end

    def get_end_date_time
      @end_date_time
    end
    
    def set_end_date_time(value)
      @end_date_time = value
      self
    end

    def __toString
      result = {
        id: @id,
        scoreMaximum: @score_maximum,
        label: @label,
        resourceId: @resource_id,
        tag: @tag,
        startDateTime: @start_date_time,
        endDateTime: @end_date_time
      }
      
      result
    end
  end
end

