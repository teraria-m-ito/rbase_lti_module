module LTI
  class LTINamesRolesProvisioningService
    @service_connector = nil
    @service_data = nil

    def initialize(service_connector, service_data)
      @service_connector = service_connector
      @service_data = service_data
    end
    
    def get_members
      members = [];
      
      next_page = @service_data['context_memberships_url']
      
      while next_page do
        page = @service_connector.make_service_request(
          ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'],
          'GET',
          next_page,
          nil,
          nil,
          'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'
        )
        
        members = members.concat(page[:body]['members'])
        next_page = false
        
        page[:headers].each do |name, header|
          re = Regexp.new(::LTI::LTIServiceConnector::NEXT_PAGE_REGEX)
          m = re.match(header)
          if m
            next_page = m[1]
            break
          end
        end
      end
      
      members
    end
  end
end