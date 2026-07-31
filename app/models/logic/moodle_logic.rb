require 'httparty'
require 'json'
require 'mechanize'

module Logic
  class MoodleLogic < Logic::LmsApiBaseLogic
    include ActiveModel::Model
    include Rails.application.routes.url_helpers

    attr_accessor :wstoken

    ##
    # 設定で定義
    # lmsのURLからLMSタイプに変換する
    # MOODLE or CANVAS
    def self.get_lms_type(target)
      lms_types = ::SystemSetting.get_setting(:lms_types, 1).to_s.split("\n")
      result = nil
      lms_types.each do |lms_type|
        lms = lms_type.split("|")[0]
        type = lms_type.split("|")[1]

        if target == lms
          result = type
          break
        end
      end

      result
    end

    ##
    # 設定で定義
    # APIで取得されるカスタムフィールド名をlms_usersのカラム名に変換する
    def self.get_lms_field_type(target)
      lms_field_names = ::SystemSetting.get_setting(:lms_field_names, 1).to_s.split("\n")
      result = nil
      lms_field_names.each do |lms_field_name|
        lms_name = lms_field_name.split("|")[0]
        lti_name = lms_field_name.split("|")[1]

        if target == lms_name
          result = lti_name
          break
        end
      end

      result
    end

    ##
    # moodle apiを通して、ユーザ情報を取得する
    def get_user_info(lms_user)
      site_id = lms_user.sites.first.id
      self.wstoken = ::SystemSetting.get_setting(:moodle_api_wstoken, site_id) unless self.wstoken
      function = "core_user_get_users_by_field"
      url = "#{lms_user.lms}/webservice/rest/server.php?wstoken=#{self.wstoken}&wsfunction=#{function}&moodlewsrestformat=json&field=username&values[0]=#{lms_user.username.to_s.downcase}"

      MoodleLogic.debug_log "[MoodleLogic][get_user_info]url:#{url}"

      response = HTTParty.post(url,
                              headers: { 'Accept' => 'application/json'}
      )

      if response.try(:code) != 200
        MoodleLogic.debug_log "[MoodleLogic][get_user_info] error:#{response.try(:code)}"
        return nil
      end

      MoodleLogic.debug_log "[MoodleLogic][get_user_info]response:#{response}"
      JSON.parse(response.body)
    end

    ##
    # moodle apiを通して、ユーザが登録している課題一覧を取得する
    def get_assign_submission_files(lms_user)
      MoodleLogic.debug_log "[MoodleLogic][get_assign_submission_files]lms_user:#{lms_user.id}"
      result = []

      # ユーザが履修しているコースを取得する
      enrolled_courses = get_users_courses(lms_user)

      enrolled_courses.each do |enrolled_course|
        # コース内の課題モジュール一覧を取得する
        assign_modules = get_assign_contents(lms_user, enrolled_course["id"])
        assign_modules.each do |assign_module|
          submission_files = get_submission_files(lms_user, assign_module["instance"])
          unless submission_files.empty?
            result << {
              course_id: enrolled_course["id"],
              course_shortname: enrolled_course["shortname"],
              course_fullname: enrolled_course["fullname"],
              assign_name: assign_module["name"],
              files: submission_files
            }
          end
        end
      end
      MoodleLogic.debug_log "[MoodleLogic][get_assign_submission_files]response:#{result}"
      result
    end

    private

    ##
    # ユーザが履修しているコースを取得する
    def get_users_courses(lms_user)
      site_id = lms_user.sites.first.id
      self.wstoken = ::SystemSetting.get_setting(:moodle_api_wstoken, site_id) unless self.wstoken

      function = "core_enrol_get_users_courses"
      url = "#{lms_user.lms}/webservice/rest/server.php?wstoken=#{self.wstoken}&wsfunction=#{function}&moodlewsrestformat=json&userid=#{lms_user.lms_user_id}"

      MoodleLogic.debug_log "[MoodleLogic][get_submission]core_enrol_get_users_courses url:#{url}"

      response = HTTParty.post(url,
                               headers: { 'Accept' => 'application/json'}
      )

      if response.try(:code) != 200
        MoodleLogic.debug_log "[MoodleLogic][get_submission]core_enrol_get_users_courses error:#{response.try(:code)}"
        return nil
      end
      MoodleLogic.debug_log "[MoodleLogic][get_user_info]response:#{response}"
      JSON.parse(response.body)
    end

    ##
    # コース内の課題モジュール一覧を取得する
    def get_assign_contents(lms_user, course_id)
      site_id = lms_user.sites.first.id
      self.wstoken = ::SystemSetting.get_setting(:moodle_api_wstoken, site_id) unless self.wstoken
      function = "core_course_get_contents"
      url = "#{lms_user.lms}/webservice/rest/server.php?wstoken=#{self.wstoken}&wsfunction=#{function}&moodlewsrestformat=json&courseid=#{course_id}"

      MoodleLogic.debug_log "[MoodleLogic][get_contents]url:#{url}"

      response = HTTParty.post(url,
                               headers: { 'Accept' => 'application/json'}
      )

      if response.try(:code) != 200
        MoodleLogic.debug_log "[MoodleLogic][get_assign_contents] error:#{response.try(:code)}"
        return nil
      end

      result = []
      MoodleLogic.debug_log "[MoodleLogic][get_assign_contents]response:#{response}"
      contents = JSON.parse(response.body)
      contents.each do |contents|
        contents["modules"].each do |mod|
          if mod["modname"] == "assign"
            result << mod
          end
        end
      end
      result
    end

    ##
    # 課題モジュールの提出物一覧を取得する
    def get_submissions(lms_user, assignment_id)
      site_id = lms_user.sites.first.id
      self.wstoken = ::SystemSetting.get_setting(:moodle_api_wstoken, site_id) unless self.wstoken
      function = "mod_assign_get_submissions"
      url = "#{lms_user.lms}/webservice/rest/server.php?wstoken=#{self.wstoken}&wsfunction=#{function}&moodlewsrestformat=json&assignmentids[0]=#{assignment_id}"

      MoodleLogic.debug_log "[MoodleLogic][get_submissions]url:#{url}"

      response = HTTParty.post(url,
                               headers: { 'Accept' => 'application/json'}
      )

      if response.try(:code) != 200
        MoodleLogic.debug_log "[MoodleLogic][get_submissions] error:#{response.try(:code)}"
        return nil
      end
      MoodleLogic.debug_log "[MoodleLogic][get_submissions]response:#{response}"
      JSON.parse(response.body)
    end

    ##
    # 課題モジュールの内で、ファイルの提出物を取得する
    def get_submission_files(lms_user, assignment_id)

      MoodleLogic.debug_log "[MoodleLogic][get_submission_files]assignment_id:#{assignment_id}"

      result = []
      submissions = get_submissions(lms_user, assignment_id)
      submissions.each do |submission|
        submission[1].each do |assignment|
          assignment["submissions"].each do |submission|
            if submission["status"] == "submitted"
              submission["plugins"].each do |plugin|
                if plugin["type"] == "file"
                  plugin["fileareas"].each do |filearea|
                    filearea["files"].each do |file|
                      result << {filename: file["filename"], fileurl: file["fileurl"], timemodified: Time.at(submission["timemodified"].to_i)}
                    end
                  end
                end
              end
            end
          end
        end
      end
      MoodleLogic.debug_log "[MoodleLogic][get_user_info]response:#{result}"
      result
    end
  end
end
