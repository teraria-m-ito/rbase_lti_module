import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"
import { get, post, put, patch, destroy } from '@rails/request.js'

export default class extends RbaseController {
  index() {
    super.index();
    if (Rbase.getParams('clear') == 'true') {
      Rbase.clearWebStorageFormValue('lti_database');
    }
  }
  
  new() {
    super.new();
  }
  
  edit() {
    super.edit();
  }
  show() {
    super.show();
    Rbase.showFormDisbaled();
  }
  
  async button_update_pem(event) {
    console.log("lti_databases_controller.js->button_update_pem()");
    event.preventDefault();
    event.stopPropagation();

    var self = this;
    if (window.confirm(self.paramsValue.build_confirm_message)) {
      const response = await get(self.paramsValue.url1, {
        contentType: "application/json"
      });
      
      if (response.ok) {
        console.log("success");
        const data = await response.json;
        $("#lti_database_private_key_file").html(data.pem);
        $("#lti_database_public_key").html(data.pub_pem);
        return false;
      }
    }
    return false;
  }
  
  async button_update_kid(event) {
    console.log("lti_databases_controller.js->button_update_kid()");
    event.preventDefault();
    event.stopPropagation();

    var self = this;
    if (window.confirm(self.paramsValue.build_confirm_message)) {
      const response = await get(self.paramsValue.url2, {
        contentType: "application/json"
      });
      
      if (response.ok) {
        const data = await response.json;
        console.log("success:"+data.kid);
        $("#lti_database_kid").val(data.kid);
        return false;
      }
    }
    return false;
  }
}
