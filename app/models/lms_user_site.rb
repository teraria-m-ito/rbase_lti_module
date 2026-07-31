class LmsUserSite < ApplicationRecord
  belongs_to :lms_user, optional: true
  belongs_to :site, optional: true

end
