module LTI
  class LTIAssignmentsGradesService
    @service_connector = nil
    @service_data = nil
    
    def initialize(service_connector, service_data)
      @service_connector = service_connector
      @service_data = service_data
    end

    def get_maxinux
      if @service_data['lineitem']
        url = @service_data['lineitem']
        result = @service_connector.make_service_request(
          @service_data['scope'],
          'GET',
          url,
          {},
          nil,
          'application/vnd.ims.lis.v2.lineitem+json'
        )
        result[:body]["scoreMaximum"]
      else
        0
      end
    end

    def put_grade(grade, lineitem = nil)
      unless @service_data['scope'].include?("https://purl.imsglobal.org/spec/lti-ags/scope/score")
        raise ::LTI::Exception.new("Missing required scope.")
      end
      
      score_url = ""
      
      if !lineitem.nil? && lineitem.get_id.nil?
        lineitem = find_or_create_lineitem(lineitem)
        score_url = lineitem.get_id
      elsif lineitem.nil? && !@service_data['lineitem'].empty?
        score_url = @service_data['lineitem']
      else
        lineitem = ::LTI::LTILineitem.new
          .set_label('default')
          .set_score_maximum(100)
        
        lineitem  = find_or_create_lineitem(lineitem)
        score_url = lineitem.get_id
      end

      # Place '/scores' before url params
      score_urls = score_url.split("?")
      
      score_url = "#{score_urls[0]}/scores"
      score_url = score_url + "?" + score_urls[1] if score_urls.size > 1

      return @service_connector.make_service_request(
        @service_data['scope'],
        'POST',
        score_url,
        JSON.generate(grade.__toString),
        'application/vnd.ims.lis.v1.score+json'
      )

    end

    def find_or_create_lineitem(new_line_item)
      unless @service_data['scope'].include?("https://purl.imsglobal.org/spec/lti-ags/scope/lineitem")
        raise ::LTI::Exception.new("Missing required scope.")
      end
      
      line_items = @service_connector.make_service_request(
        @service_data['scope'],
        'GET',
        @service_data['lineitems'],
        nil,
        nil,
        'application/vnd.ims.lis.v2.lineitemcontainer+json'
      )
      
      line_items[:body].each do |line_item|
        if new_line_item.get_resource_id.empty? || line_item['resourceId'] == new_line_item.get_resource_id
          if new_line_item.get_tag.empty? || line_item['tag'] == new_line_item.get_tag
            return ::LTI::LTILineitem.new(line_item)
          end
        end
      end
      
      created_line_item = @service_connector.make_service_request(
        @service_data['scope'],
        'POST',
        @service_data['lineitems'],
        JSON.generate(new_line_item.__toString),
        'application/vnd.ims.lis.v2.lineitem+json',
        'application/vnd.ims.lis.v2.lineitem+json'
      )
      
      ::LTI::LTILineitem.new(created_line_item[:body])
    end

    def get_grades(lineitem)
      lineitem = find_or_create_lineitem(lineitem)
      # Place '/results' before url params
      results_urls = lineitem.get_id.split("?")
      
      results_url = "#{results_urls[0]}/results"
      results_url = results_url + "?" + results_urls[1] if results_urls.size > 1
      
      scores = @service_connector.make_service_request(
        @service_data['scope'],
        'GET',
        results_url,
        nil,
        nil,
        'application/vnd.ims.lis.v2.resultcontainer+json'
      )
      
      scores[:body]
    end
  end
end