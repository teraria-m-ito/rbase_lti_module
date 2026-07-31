import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"
import { get, post, put, patch, destroy } from '@rails/request.js'

const SEARCH_FORM_NAME = 'LTI_orgs/search_conditions';
const FORM_NAME = 'LTI_org';

const commonInit = function(self) {
  if (Rbase.getParams('clear') == 'true') {
    Rbase.clearWebStorageFormValue(FORM_NAME);
  }
};

export default class extends RbaseController {
  connect() {
    super.connect();
  }
  
  index() {
    super.index();
    console.log("orgs_controller.js->index()");
    var self = this;

    $("#lti_orgs_search_conditions").off("change");
    $("#lti_orgs_search_conditions").on("change", function(e) {
      Rbase.saveWebStorageFormValue($(e.target).prop('id'), SEARCH_FORM_NAME);
    });
    
    Rbase.restoreWebStorageFormValueNoTrigger(SEARCH_FORM_NAME);
    commonInit(self);
  }
  
  new() {
    super.new();
    console.log("orgs_controller.js->new()");

    var self = this;
    Rbase.restoreWebStorageFormValueNoTrigger(FORM_NAME);
    commonInit(self);
  }
  
  edit() {
    super.edit();
    console.log("orgs_controller.js->edit()");

    var self = this;
    Rbase.restoreWebStorageFormValueNoTrigger(FORM_NAME);
    commonInit(self);
  }
  
  show() {
    super.show();
    console.log("orgs_controller.js->show()");
    var self = this;

    Rbase.showFormDisbaled();
  }
}