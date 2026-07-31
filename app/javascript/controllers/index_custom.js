import {application} from "@app_root/app/javascript/controllers/application"

import Admin__DatebasesController from "./admin/lti_databases_controller"
application.register("admin--lti_databases", Admin__DatebasesController)

import LmsUsersController from "./lms_users_controller"
application.register("lms_users", LmsUsersController)

import LmsUserImportsController from "./lms_user_imports_controller"
application.register("lms_user_imports", LmsUserImportsController)

import LTIOrgsController from "./LTI/orgs_controller"
application.register("lti--orgs", LTIOrgsController)

import LTIOperationLogsController from "./LTI/operation_logs_controller"
application.register("lti--operation_logs", LTIOperationLogsController)


import LTIImportHistoriesController from "./LTI/import_histories_controller"
application.register("lti--import_histories", LTIImportHistoriesController)
