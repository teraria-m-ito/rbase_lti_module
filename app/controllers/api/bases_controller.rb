module Api
  class BasesController < ::Lti::BasesController
    def reject_redirect_root
      true
    end
  end
end