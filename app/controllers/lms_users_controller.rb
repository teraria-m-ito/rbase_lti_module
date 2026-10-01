class LmsUsersController < CustomUserApplicationController
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）

  before_action :set_new_lms_user, only: [:new]
  before_action :set_lms_user, only: [:show, :edit, :update, :destroy]
  before_action :setup_values, only: [:index, :show, :new, :create, :edit, :update]
  before_action :set_lms_user_custom_fields, only: [:new, :edit, :show]
  before_action :set_inst_dept
  skip_before_action :check_permission, only: [:stop_proxy_login, :switch_role]

  respond_to :html
  def index
    if params[:lms_users_search_conditions]
      @condition = ::LmsUsers::SearchConditions.new(search_condition_params)
      return render 'index' unless @condition.valid?
      @condition.current_admin_user = current_admin_user
      session[:lms_users_search_conditions] = @condition

      @lms_users = @condition.search.page(params[:page])
    else
      if session[:lms_users_search_conditions]
        @condition = session[:lms_users_search_conditions]
        @condition.current_admin_user = current_admin_user
        @lms_users = @condition.search.page(params[:page])
      else
        @condition = ::LmsUsers::SearchConditions.new
        @condition.current_admin_user = current_admin_user
        @lms_users = @condition.search.page(params[:page])
      end
    end
    render_index
  end

  private
  def render_index;end
  public

  def show
    render_show
  end

  private
  def render_show;end
  public

  def new
    render_new
  end

  private
  def render_new(status = nil)
    if status.nil?
      render :new
    else
      render :new, status: status
    end
  end
  public

  def edit
    render_edit
  end

  private
  def render_edit(status = nil)
    if status.nil?
      render :edit
    else
      render :edit, status: status
    end
  end
  public

  def create
    @lms_user = ::LmsUser.new(lms_user_params)
    @lms_user.lti_org_id = @lms_user.dept_org_id
    if @lms_user.valid?
      target_site_id = @lms_user.sites.sort.first.id
      admin_user = @lms_user.admin_user || ::AdminUser.joins(:admin_user_sites).where(name: @lms_user.username).where("site_id IN (?)",  target_site_id).first ||::AdminUser.new
      set_admin_user_attr(admin_user)
      if admin_user.valid?
        admin_user.save!
        @lms_user.admin_user = admin_user
        @lms_user.save!
        @lms_user.create_admin_user
        flash[:notice] = t("views.common.create_complete_message")
        redirect_to_create
      else
        unless admin_user.role
          admin_user.errors.add(:base, I18n.t("activerecord.errors.models.admin_user.attributes.role.invalid_role"))
        end
        flash[:alert] = admin_user.errors.full_messages.uniq.join("<br/>").html_safe
        set_lms_user_custom_fields
        render_new(:unprocessable_entity)
      end
    else
      set_lms_user_custom_fields
      render_new(:unprocessable_entity)
    end
  end

  private
  def redirect_to_create
    redirect_to lms_users_path, status: :see_other
  end
  public

  def update
    @lms_user.assign_attributes(lms_user_params)
    @lms_user.lti_org_id = @lms_user.dept_org_id
    if @lms_user.valid?
      admin_user = @lms_user.admin_user
      set_admin_user_attr(admin_user)
      if admin_user.valid?
        admin_user.save!
        @lms_user.save!
        @lms_user.create_admin_user(true)
        flash[:notice] = t("views.common.update_complete_message")
        redirect_to lms_users_path, status: :see_other
      else
        unless admin_user.role
          admin_user.errors.add(:base, I18n.t("activerecord.errors.models.admin_user.attributes.role.invalid_role"))
        end
        flash[:alert] = admin_user.errors.full_messages.uniq.join("<br/>").html_safe
        set_lms_user_custom_fields
        render_edit(:unprocessable_entity)
      end
    else
      set_lms_user_custom_fields
      render_edit(:unprocessable_entity)
    end
  end

  def destroy
    flash[:notice] = t("views.common.destroy_complete_message") if @lms_user.destroy
    redirect_to lms_users_path, status: :see_other
  end

  desc :display_name => "lms_users_proxy_login"
  def proxy_login
    @lms_user = ::LmsUser.find_by(id: params[:id])
    unless @lms_user
      flash[:alert] = t(:"views.lms_users.proxy_login.alert_failed")
      return redirect_to lms_users_path
    end
    if session[:proxy_login_original_user_id].present?
      flash[:alert] = t(:"views.lms_users.proxy_login.alert_already")
      return redirect_to lms_user_path(@lms_user)
    end
    if current_lms_user.try(:id) == @lms_user.id
      flash[:alert] = t(:"views.lms_users.proxy_login.alert_self")
      return redirect_to lms_user_path(@lms_user)
    end

    original_admin_user_id = current_admin_user.id
    original_lms_user_id = session[:current_lms_user].try(:id)
    admin_user = @lms_user.admin_user
    begin
      admin_user = admin_user || @lms_user.create_admin_user
    rescue StandardError => e
      ::Rails.logger.error("proxy_login create_admin_user: #{e.class} #{e.message}")
      admin_user = nil
    end
    unless admin_user.try(:persisted?)
      flash[:alert] = t(:"views.lms_users.proxy_login.alert_failed")
      return redirect_to lms_user_path(@lms_user)
    end

    sign_out(current_admin_user) if current_admin_user
    sign_in(admin_user)
    session[:proxy_login_original_user_id] = original_admin_user_id
    session[:proxy_login_original_lms_user_id] = original_lms_user_id
    session[:current_lms_user] = @lms_user
    assign_selected_site_from_allowed!
    flash[:notice] = t(:"views.lms_users.proxy_login.notice_started")
    redirect_to root_path
  end

  desc :display_name => "lms_users_switch_role"
  def switch_role
    lms_user = session[:current_lms_user]
    lms_user = ::LmsUser.find_by(id: lms_user.id) if lms_user.try(:id)
    lms_user ||= ::LmsUser.where(admin_user_id: current_admin_user.id).first
    role = ::Role.find_by(id: params[:role_id])
    owned = lms_user && role && (lms_user.roles.exists?(id: role.id) || current_admin_user.try(:role_id) == role.id)
    unless owned
      flash[:alert] = t(:"views.lms_users.switch_role.alert_failed")
      return redirect_back fallback_location: root_path
    end

    entries = ::LmsUser.role_entries.select { |e| e[:role_name].to_s == role.role_short_name.to_s }
    entry = entries.find { |e| e.id.to_s == lms_user.role.to_s } ||
            entries.find { |e| e.id.to_s.casecmp(role.role_short_name.to_s).zero? } ||
            entries.max_by { |e| e[:prio].to_i }
    lms_user.role = entry[:id] if entry
    lms_user.save! if lms_user.changed?

    current_admin_user.role_id = role.id
    current_admin_user.save!

    session[:current_lms_user] = lms_user

    role_div = lms_user.role_entry.try(:[], :role_div)
    site_id = request_site_id
    path = nil
    if role_div.present? && site_id.present?
      launch_urls = SystemSetting.get_multivalue_list(:canvas_redirect_url, site_id)
      path = launch_urls.find { |x| x[:value_div].to_s == role_div.to_s }.try(:[], :value).to_s.strip
      path = path.present? ? (path.start_with?("/") ? path : "/#{path}") : nil
    end
    if path.blank?
      Rails.logger.error("canvas_redirect_url 未設定 role=#{lms_user.role.inspect} role_div=#{role_div.inspect} site_id=#{site_id.inspect}")
      flash[:alert] = t(:"views.lms_users.switch_role.alert_failed")
      return redirect_back fallback_location: root_path
    end
    redirect_to path
  end

  def stop_proxy_login
    original_admin_user_id = session[:proxy_login_original_user_id]
    original_lms_user_id = session[:proxy_login_original_lms_user_id]
    impersonated_lms_user_id = session[:current_lms_user].try(:id)
    unless original_admin_user_id.present?
      return redirect_to root_path
    end

    original_admin_user = ::AdminUser.find_by(id: original_admin_user_id)
    unless original_admin_user
      flash[:alert] = t(:"views.lms_users.proxy_login.alert_failed")
      return redirect_to root_path
    end

    sign_out(current_admin_user) if current_admin_user
    sign_in(original_admin_user)
    session[:proxy_login_original_user_id] = nil
    session[:proxy_login_original_lms_user_id] = nil
    session[:current_lms_user] = original_lms_user_id.present? ? ::LmsUser.find_by(id: original_lms_user_id) : ::LmsUser.where(admin_user_id: original_admin_user.id).first
    assign_selected_site_from_allowed!
    flash[:notice] = t(:"views.lms_users.proxy_login.notice_stopped")
    if impersonated_lms_user_id.present? && ::LmsUser.exists?(impersonated_lms_user_id)
      redirect_to lms_user_path(impersonated_lms_user_id)
    else
      redirect_to lms_users_path
    end
  end
  private

  def setup_values
    @sites = current_admin_user.sites.all
  end

  def assign_selected_site_from_allowed!
    return unless current_admin_user

    site_id = request_site_id
    allowed = Array(current_admin_user.site_ids).map(&:to_i).uniq.select { |id| accepted_site_id(id) }
    site_id = nil if site_id.present? && !allowed.include?(site_id)
    site_id = allowed.first if site_id.blank? && allowed.size == 1
    current_admin_user.selected_site = site_id if site_id
  end

  def set_new_lms_user
    @lms_user = ::LmsUser.new
  end

  def set_lms_user
    @lms_user = LmsUser.find(params[:id])
  end

  def set_inst_dept
    @institutions = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:institution)).all
    @departments = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:department)).order(:parent_org_id).all
    @courses = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:course)).all
  end

  def search_condition_params
    params[:lms_users_search_conditions][:sites].to_a.reject!{|x|x.blank?}
    params.require(:lms_users_search_conditions).permit!
  end

  def lms_user_params
    params.require(:lms_user).permit!
  end

  def set_admin_user_attr(admin_user)
    admin_user.name = @lms_user.username
    admin_user.email = @lms_user.email
    role_name = @lms_user.role_entry[:role_name]
    role = ::Role.where(role_short_name: role_name).first
    admin_user.role = role
    admin_user.sites = @lms_user.sites
    if @lms_user.password.present? || @lms_user.password_confirmation.present?
      admin_user.password = @lms_user.password
      admin_user.password_confirmation = @lms_user.password_confirmation
    elsif admin_user.new_record?
      admin_user.password = SecureRandom.urlsafe_base64
    end
  end

  def set_lms_user_custom_fields
    @custom_fields = CustomField.lms_users
    @custom_fields.each do |custom_field|
      @lms_user.lms_user_custom_fields << LmsUserCustomField.new(custom_field_id: custom_field.id) unless @lms_user.lms_user_custom_fields.map(&:custom_field_id).include?(custom_field.id)
    end
  end
end
