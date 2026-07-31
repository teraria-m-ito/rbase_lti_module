Rails.application.routes.draw do

  resources :top do
  end

  get 'launch_application', to: "common#launch_application"

  namespace :admin do
    resources :lti_databases do
      collection do
        get 'button_update_pem'
        get 'button_update_kid'
      end
    end
  end

  resources :lms_users

  resource :lms_user_imports do
    collection do
      get 'download'
    end
    resources :lms_user_import_attachments do
      collection do
        patch 'create'
      end
    end
  end

  namespace :lti do

    #マスタ系
    #学部・学科管理
    resources :orgs

    # 操作ログ一覧
    resources :operation_logs do
    end

    resources :import_histories

  end

  namespace :api do
    namespace :lti do
      get :"tool/register", to: "lti_tool_register#new"
      post :"tool/register", to: "lti_tool_register#new"
    end
  end
end
