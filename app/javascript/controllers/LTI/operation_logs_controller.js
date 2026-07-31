import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"
import { get, post, put, patch, destroy } from '@rails/request.js'

const SEARCH_FORM_NAME = 'LTI_operation_logs/search_conditions';
const FORM_NAME = 'LTI_operation_log';


export default class extends RbaseController {
  connect() {
    super.connect();
    Rbase.resetTableXOffset();
  }
  
  index() {
    super.index();
    var self = this;

    if (Rbase.getParams('clear') == 'true') {
      Rbase.clearWebStorageFormValue(SEARCH_FORM_NAME);
    }
    
    Rbase.initValueWebStorageFormValue("#lti_operation_logs_search_conditions", FORM_NAME);
    
    $("#lti_operation_logs_search_conditions").off("change");
    $("#lti_operation_logs_search_conditions").on("change", function(e) {
      Rbase.saveWebStorageFormValue($(e.target).prop('id'), SEARCH_FORM_NAME);
    });
    
    Rbase.restoreWebStorageFormValueNoTrigger(SEARCH_FORM_NAME);
    
    setTimeout(function(){
      Rbase.restoreTableXOffset();
      Rbase.saveTableXOffset();
    }, 100);
    
    Rbase.showLoading();
    
  }
}