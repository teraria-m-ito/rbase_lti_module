# coding: utf-8
class CustomUserApplicationController < UserApplicationController
  before_action :redirect_root

  def current_lms_user
    session[:current_lms_user]
  end

end

