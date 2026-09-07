class CustomAdminApplicationController < AdminApplicationController
  prepend_view_path 'custom/app/views'

  def current_lms_user
    session[:current_lms_user]
  end

end
