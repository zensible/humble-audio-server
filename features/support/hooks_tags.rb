Before do |scenario|
  DatabaseCleaner.clean()
  $test_mode = 'browser'
end

# Wait up to 5 seconds for code block to return true
def wait_until(max=5, wait_time=0.15)
  start = Time.now.to_f
  begin
    yield
  rescue Exception => ex
    if (Time.now - start).to_f > max
      puts "== waited max #{max} seconds" if ENV['VERBOSE'] == 'true'
      raise
    else
      sleep(wait_time)
      retry
    end
  end
end


def screenie()
  @screenNum ||= 0
  @screenNum += 1

  nam = "screen_#{@screenNum}.png"
  puts "== Saving screenshot: #{nam}"
  save_screenshot("./#{nam}", :full => true)
end

def clear_notifications
  page.evaluate_script("$('.notifyjs-corner').empty();")
end

Before('@music_exists') do
  visit("/")

  # Populates the DB. Also tests the 'sync' feature (app/models/sync.rb)

  page.evaluate_script("localStorage.clear()")

  config   = Rails.configuration.database_configuration
  host     = config[Rails.env]["host"]
  database = config[Rails.env]["database"]
  username = config[Rails.env]["username"]
  password = config[Rails.env]["password"]

  if File.exist?("dump_test.sql") && ENV['REFRESH_DB'] != 'true'
    # If mp3s were already sync'd once, use the resulting db dump. Speeds tests up by a good 60s
    puts "== READING DB FROM DISK"
    cmd = "mysql --user #{username} -p#{password} #{database} < dump_test.sql"
    puts cmd
    `#{cmd}`
  else
    # Go through and sync existing mp3s in each category
    sql = "DROP DATABASE #{database};"
    ActiveRecord::Base.connection.execute(sql)
    `rake db:create`
    `rake db:migrate`
    puts "== POPULATING DB."
    # Be sure to DROP DATABASE, rake db:create and rake db:migrate if there have been any DB schema changes

    page.find(".select-mode", :text => 'Music').click()
    page.text.should match(/No mp3s found/)
    page.find("#refresh-media").click()
    page.text.should match(/4 added. 4 mp3s total/)
    clear_notifications

    page.find(".select-mode", :text => 'White Noise').click()
    page.text.should match(/No mp3s found/)
    page.find("#refresh-media").click()
    page.text.should match(/1 added. 1 mp3s total/)
    clear_notifications

    page.find(".select-mode", :text => 'Spoken').click()
    page.text.should match(/No mp3s found/)
    page.find("#refresh-media").click()
    page.text.should match(/4 added. 4 mp3s total/)
    clear_notifications

    cmd = "mysqldump --user #{username} -p#{password} --databases #{database} > dump_test.sql"
    puts cmd
    `#{cmd}`
  end

end
