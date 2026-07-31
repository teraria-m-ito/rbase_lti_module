# coding: utf-8

namespace :lti do
  desc "import lms users."
  task :import_lms_users, [:file_name, :site_id] => :environment do |task, args|
    puts "[import_lms_users]start...."
    ::LmsUserImport.import_lms_users(args[:file_name], args[:site_id])
    puts "[import_lms_users]finished...."
  end
end
