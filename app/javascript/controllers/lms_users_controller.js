import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"
import { get, post, put, patch, destroy } from '@rails/request.js'
import { RbaseLtiModuleCommon } from "@app_root/rbase_gems/rbase_lti_module/app/javascript/lti_module_common.js"

const SEARCH_FORM_NAME = 'lms_users/search_conditions';
const FORM_NAME = 'lms_user';

export default class extends RbaseController {
  index() {
    super.index();
    console.log("lms_users_controller.js->index()");
    if (Rbase.getParams('clear') == 'true') {
      Rbase.clearWebStorageFormValue(SEARCH_FORM_NAME);
    }
  }
  
  new() {
    super.new();
    console.log("lms_users_controller.js->new()");
    if (Rbase.getParams('clear') == 'true') {
      Rbase.clearWebStorageFormValue(FORM_NAME);
    }
    Rbase.restoreWebStorageFormValueNoTrigger(FORM_NAME);
    
    RbaseLtiModuleCommon.initSelectInstDept();
    RbaseLtiModuleCommon.selectInstDept();
    this.bindPasswordToggle();
  }
  
  edit() {
    super.edit();
    console.log("lms_users_controller.js->edit()");
    if (Rbase.getParams('clear') == 'true') {
      Rbase.clearWebStorageFormValue(FORM_NAME);
    }
    Rbase.restoreWebStorageFormValueNoTrigger(FORM_NAME);
    
    RbaseLtiModuleCommon.initSelectInstDept();
    RbaseLtiModuleCommon.selectInstDept();
    this.bindPasswordToggle();
  }

  bindPasswordToggle() {
    $("#toggle-password").on('click', function() {
      if ($('#lms_user_password').attr('type') == 'password') {
        $('#lms_user_password').attr('type','text');
        $(this).removeClass('bi-eye-slash');
        $(this).addClass('bi-eye');
      } else {
        $('#lms_user_password').attr('type','password');
        $(this).removeClass('bi-eye');
        $(this).addClass('bi-eye-slash');
      }
    });

    $("#toggle-password-confirm").on('click', function() {
      if ($('#lms_user_password_confirmation').attr('type') == 'password') {
        $('#lms_user_password_confirmation').attr('type','text');
        $(this).removeClass('bi-eye-slash');
        $(this).addClass('bi-eye');
      } else {
        $('#lms_user_password_confirmation').attr('type','password');
        $(this).removeClass('bi-eye');
        $(this).addClass('bi-eye-slash');
      }
    });
  }
  
  show() {
    super.show();
    console.log("lms_users_controller.js->show()");
    Rbase.showFormDisbaled();
  }
  
}
