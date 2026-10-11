module LTI
  class LTICourseGroupsService
    @service_connector = nil
    @service_data = nil

    def initialize(service_connector, service_data)
      @service_connector = service_connector
      @service_data = service_data
    end

    def get_groups
      fetch_all_pages(@service_data['context_groups_url'], 'groups')
    end

    def get_sets
      # Sets are optional.
      return [] if @service_data['context_group_sets_url'].blank?

      fetch_all_pages(@service_data['context_group_sets_url'], 'sets')
    end

    def get_groups_by_set
      groups_by_set = {}
      unsetted = {}

      get_sets.each do |set|
        groups_by_set[set['id']] = set.merge('groups' => {})
      end

      get_groups.each do |group|
        if group['set_id'].present? && groups_by_set[group['set_id']]
          groups_by_set[group['set_id']]['groups'][group['id']] = group
        else
          unsetted[group['id']] = group
        end
      end

      unless unsetted.empty?
        groups_by_set['none'] = {
          'name' => "None",
          'id' => "none",
          'groups' => unsetted
        }
      end

      groups_by_set
    end

    private

    def fetch_all_pages(url, key)
      result = []
      next_page = url
      while next_page do
        page = @service_connector.make_service_request(
          @service_data['scope'],
          'GET',
          next_page,
          nil,
          nil,
          'application/vnd.ims.lti-gs.v1.contextgroupcontainer+json'
        )
        result.concat(Array(page[:body].try(:[], key)))
        next_page = ::LTI::LTIServiceConnector.next_page_url(page[:headers])
      end
      result
    end
  end
end
