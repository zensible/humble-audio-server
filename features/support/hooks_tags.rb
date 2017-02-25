

def screenie()
  @screenNum ||= 0
  @screenNum += 1

  nam = "screen_#{@screenNum}.png"
  puts "== Saving screenshot: #{nam}"
  save_screenshot(nam, :full => true)
end

def clear_notifications
  page.evaluate_script("$('.notifyjs-corner').empty();")
end

Before('@music_exists') do
  visit("/")

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
end
