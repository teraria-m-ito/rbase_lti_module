class LmsUsersController < CustomUserApplicationController
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）

  before_action :set_new_lms_user, only: [:new]
  before_action :set_lms_user, only: [:show, :edit, :update, :destroy]
  before_action :setup_values, only: [:index, :show, :new, :create, :edit, :update]
  before_action :set_lms_user_custom_fields, only: [:new, :edit, :show]
  before_action :set_inst_dept

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
  private

  def setup_values
    @sites = current_admin_user.sites.all
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
    admin_user.password = SecureRandom.urlsafe_base64 if admin_user.new_record?
  end

  def set_lms_user_custom_fields
    @custom_fields = CustomField.lms_users
    @custom_fields.each do |custom_field|
      @lms_user.lms_user_custom_fields << LmsUserCustomField.new(custom_field_id: custom_field.id) unless @lms_user.lms_user_custom_fields.map(&:custom_field_id).include?(custom_field.id)
    end
  end
end
