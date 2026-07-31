require "csv"

tables = [
  "issue_type_sites",
  "issue_types",
  "workflow_sites",
  "workflows",
  "workflow_states",
  "workflow_sites",
  "system_setting_sites",
  "system_settings"
]

tables.each do |table|
  puts "========== seed #{table}"
  headers = nil
  index = 0
  ActiveRecord::Base.transaction do
    CSV.foreach("rbase_gems/rbase_lti_module/db/csv/#{table}.csv") do |row|
      puts "\t#{index}/#{row}"
      if index == 0
        headers = row
      else
        class_name = table.singularize.classify
        puts "#{class_name}.find_by(id: #{row[0]}) || #{class_name}.new"
        instance = eval("#{class_name}.find_by(id: row[0]) || #{class_name}.new")
        headers.each_with_index do |header, j|
          next if j == 0
          data = row[j] == "NULL" ? nil : row[j]
          instance.send("#{header}=", data)
        end
        begin
          instance.save!(validate: false)
        rescue => e
          puts instance.errors.full_messages
          raise e
        end
      end
      index = index + 1
    end
  end
end
