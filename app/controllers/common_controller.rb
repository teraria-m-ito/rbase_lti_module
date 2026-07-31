# coding: utf-8
class CommonController < UserApplicationController

  before_action :redirect_root

  def launch_application
    if params[:redirect]
      redirect_to params[:redirect]
      return
    end
    _render_403
  end
end