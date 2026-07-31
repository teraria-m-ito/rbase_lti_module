import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"
import { get, post, put, patch, destroy } from '@rails/request.js'

const FORM_NAME = 'lms_user_imports';

export default class extends RbaseController {
  connect() {
    super.connect();
  }
  
  new() {
    console.log("lms_user_imports_controller -> new");
    super.new();
    var self = this;
    
    $('#fileupload').fileupload({
      maxNumberOfFiles: 1,
      downloadTemplateId: null,
      sequentialUploads: true,
      acceptFileTypes: /(\.|\/)(xlsx|XLSX)$/i,
      method: 'patch',
      url: self.paramsValue.url1,
      done: function (e, data) {
        $("form").submit();
      }
    });
    
    $("input[type='submit']").on('click', function() {
      console.log("submit");
      if (window.confirm(self.paramsValue.confirm_message)) {
        if ($(".template-upload").length > 0) {
          $('#upload-btn').click();
        } else {
          $("form").submit();
        }
      }
      return false;
    });
  }
  
}