import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"
import { get, post, put, patch, destroy } from '@rails/request.js'

const SEARCH_FORM_NAME = 'LTI_csv_histories/search_conditions';
const FORM_NAME = 'LTI_csv_history';

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
    console.log("import_histories_controller.js->index()");
    var self = this;
    
    if (Rbase.getParams('clear') == 'true') {
      Rbase.clearWebStorageFormValue(SEARCH_FORM_NAME);
    }
    
    $("#lti_import_histories_search_conditions").off("change");
    $("#lti_import_histories_search_conditions").on("change", function(e) {
      Rbase.saveWebStorageFormValue($(e.target).prop('id'), SEARCH_FORM_NAME);
    });
    
    Rbase.restoreWebStorageFormValueNoTrigger(SEARCH_FORM_NAME);
    commonInit(self);
  }
  
  show() {
    super.show();
    console.log("import_histories_controller.js->show()");
    var self = this;
    
    Rbase.showFormDisbaled();
  }
}