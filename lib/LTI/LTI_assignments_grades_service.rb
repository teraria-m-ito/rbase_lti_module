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
      unless Array(@service_data['scope']).include?("https://purl.imsglobal.org/spec/lti-ags/scope/score")
        raise ::LTI::Exception.new("Missing required scope.")
      end
      
      score_url = ""
      
      if lineitem && lineitem.get_id.present?
        # id が分かっている lineitem はそのまま使う
        score_url = lineitem.get_id
      elsif lineitem
        lineitem = find_or_create_lineitem(lineitem)
        score_url = lineitem.get_id
      elsif @service_data['lineitem'].present?
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
      unless Array(@service_data['scope']).include?("https://purl.imsglobal.org/spec/lti-ags/scope/lineitem")
        raise ::LTI::Exception.new("Missing required scope.")
      end

      # lineitem が複数ページにまたがる場合も、全ページから探してから作成する（重複作成を防ぐ）
      next_page = @service_data['lineitems']
      while next_page do
        line_items = @service_connector.make_service_request(
          @service_data['scope'],
          'GET',
          next_page,
          nil,
          nil,
          'application/vnd.ims.lis.v2.lineitemcontainer+json'
        )

        Array(line_items[:body]).each do |line_item|
          if new_line_item.get_resource_id.blank? || line_item['resourceId'] == new_line_item.get_resource_id
            if new_line_item.get_tag.blank? || line_item['tag'] == new_line_item.get_tag
              return ::LTI::LTILineitem.new(line_item)
            end
          end
        end
        next_page = ::LTI::LTIServiceConnector.next_page_url(line_items[:headers])
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
      
      results = []
      next_page = results_url
      while next_page do
        scores = @service_connector.make_service_request(
          @service_data['scope'],
          'GET',
          next_page,
          nil,
          nil,
          'application/vnd.ims.lis.v2.resultcontainer+json'
        )
        results.concat(Array(scores[:body]))
        next_page = ::LTI::LTIServiceConnector.next_page_url(scores[:headers])
      end

      results
    end
  end
end