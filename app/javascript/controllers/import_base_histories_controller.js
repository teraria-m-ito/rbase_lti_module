import * as Rbase from "@app_root/app/javascript/rbase_common.js"
import { RbaseController } from "@app_root/app/javascript/rbase_stimulus.js"

export default class extends RbaseController {
  show() {
    super.show();
    Rbase.showFormDisbaled();
  }
}
