module LTI
  class LTICourseGroupsService
    @service_connector = nil
    @service_data = nil

    def initialize(service_connector, service_data)
      @service_connector = service_connector
      @service_data = service_data
    end

    def get_groups
      groups = {}
      
      next_page = service_data['context_groups_url']
      
      while next_page do
        page = service_connector.make_service_request(
          service_data['scope'],
          'GET',
          next_page,
          nil,
          nil,
          'application/vnd.ims.lti-gs.v1.contextgroupcontainer+json'
        )
        groups = groups.merge(page['body']['groups'])
        
        next_page = false
        
        page['headers'].each do |header|
          re = Regexp.new(::LTI::LTIServiceConnector::NEXT_PAGE_REGEX)
          m = re.match(header)
          if m
            next_page = m[1]
            break
          end
        end
      end
      groups
    end

    def get_sets
      sets = {}
      
      # Sets are optional.
      next_page = service_data['context_group_sets_url']
      
      return {} if next_page.nil?
      
      while next_page do
        page = service_connector.make_service_request(
          service_data['scope'],
          'GET',
          next_page,
          nil,
          nil,
          'application/vnd.ims.lti-gs.v1.contextgroupcontainer+json'
        )
        sets = sets.merge(page['body']['sets'])
        
        next_page = false
        
        page['headers'].each do |header|
          re = Regexp.new(::LTI::LTIServiceConnector::NEXT_PAGE_REGEX)
          m = re.match(header)
          if m
            next_page = m[1]
            break
          end
        end
      end
      sets
    end

    def get_groups_by_set
      groups = get_groups
      sets = get_sets
      
      groups_by_set = {}
      unsetted = {}
      
      sets.each do |key, set|
        groups_by_set[set['id']] = set
        groups_by_set[set['id']]['groups'] = {};
      end

      groups.each do |key, group|
        unless group['set_id'].nil? || groups_by_set[$group['set_id']].nil?
          groups_by_set[group['set_id']]['groups'][group['id']] = group
        else
          unsetted[group['id']] = group
        end
      end
      
      if unsetted.empty?
        groups_by_set['none'] = {
          name: "None",
          id: "none",
          groups: unsetted
        }
      end
      
      groups_by_set
    end
  end
end