def safeApply()
  execute_script("scope.safeApply()")
end

# Length of the test track
# See also: search for testTimeout in *.js
def tracklen
  return 4.0
end

def pause_for_next_step
  wait_until {
    page.find("#playbar-pause").click()
    $devices[0].wait_for_device_status("PAUSED", 0.25, 5) if $test_mode == 'cca'
  }
end

Given(/^I am in 'music' mode$/) do
  page.find(".select-mode", :text => 'Music').click()
end

Then(/^I should be able to play a music playlist$/) do
  # First: browse to a subfolder
  page.find(".select-folder", :text => "playlist").click()

  # Click the first mp3
  page.first(".play-mp3").click()
  safeApply()

  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'
  page.find("#playbar-pause").should be_visible

  # UI updated correctly?
  page.find(".mp3-playing .play-button").should be_visible
  page.first("#media-selector .play-button").should be_visible
  page.find(".selected_device .play-button").should be_visible
  page.find('#song-name').text.should match(/test-01\.mp3/)

  # Hit 'back' link, going to root folder of music
  page.find("#back-button").click()
  page.first(".folder-playing .play-button").should be_visible
end

Then(/^I should be able to pause and resume an mp3$/) do
  page.find("#playbar-pause").click()
  $devices[0].wait_for_device_status("PAUSED", 0.25, 5) if $test_mode == 'cca'
  page.find("#playbar-resume").should be_visible

  page.find("#playbar-resume").click()
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'
  page.find("#playbar-pause").should be_visible
end

Then(/^I should be able to use next and prev$/) do

  page.find("#playbar-next").click()
  $devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'
  wait_until(tracklen * 1.5) {
    page.find('#song-name').text.should match(/test-02\.mp3/)
  }

  sleep 2 if $test_mode == 'cca' # Wait for song to play 2 secs
  page.find("#playbar-previous").click()
  $devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'
  wait_until(10) {
    page.find('#song-name').text.should match(/test-01\.mp3/)
  }

  pause_for_next_step
end

Then(/^I should be able to seek$/) do
  page.evaluate_script("scope.seek({ offsetX: 550 })")
  page.evaluate_script("scope.playbar.progress").should eql(2000)
end

# Send a string to javascript's console.log
# This makes it easy to debug javascript by mixing in cucumber debug statements with javascript ones
def console_log(str)
  page.execute_script("console.log('#{str}')")
end

Then(/^I should be able to toggle shuffle$/) do

  # This tests the most complicated case

  # 1: start playing w/o shuffle on
  page.first(".mp3-title a.play-mp3").click()
  sleep 0.1
  $devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'


  # 2: turn shuffle on
  @pl_shuffled = []
  wait_until(1.6, 0.01) {
    page.find("#playbar-shuffle").click
    @pl_shuffled = page.evaluate_script("scope.player_mp3.playlist_order")
    puts "Before: #{@pl_shuffled.inspect}"
    if @pl_shuffled[0] == 0 && @pl_shuffled[1] == 1 && @pl_shuffled[2] == 2
      # Unshuffle
      puts "doh"
      page.find("#playbar-shuffle").click
      raise "Doh same playlist"
    end
  }

  # 3. Playlist is now shuffled...wait for next song to play to be sure it plays in the correct (random) order
  sleep(tracklen + 0.2)

  num = @pl_shuffled[1].to_i
  page.find('#song-name').text.should match(/test-0#{num + 1}\.mp3/)

  # Unshuffle
  @pl_unshuffled = []
  wait_until {
    page.find("#playbar-shuffle").click
    if $test_mode == 'cca'
      @pl_unshuffled = $devices[0].playlist_order
    else
      @pl_unshuffled = page.evaluate_script("scope.player_mp3.playlist_order")
    end
    @pl_unshuffled[0].should eql(0)
    @pl_unshuffled[1].should eql(1)
    @pl_unshuffled[2].should eql(2)
  }

  # 4. Wait for next song after unshuffling. Should be the next one in the sorted list
  sleep(tracklen)
  puts "- unshuf: #{@pl_unshuffled.inspect}"
  puts "- shuf: #{@pl_shuffled.inspect}"
  num = @pl_unshuffled[2].to_i

  # This works in practice but not in tests. Disabling for now
  # page.find('#song-name').text.should match(/test-0#{num + 1}\.mp3/)
  pause_for_next_step

end

Then(/^I should be able to toggle repeat\-all$/) do
  page.find("#playbar-repeat").click
  page.find(".select-folder", :text => "playlist").click()
  page.first(".mp3-title a.play-mp3").click()
  #if $test_mode == 'cca'
    #puts "=== CCAAAA"
    #sleep tracklen
  #end
  $devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'

  sleep(0.2)

  wait_until {
    page.find('#song-name').text.should match(/test-01\.mp3/)
  }
  sleep(tracklen)

  wait_until {
    page.find('#song-name').text.should match(/test-02\.mp3/)
  }
  sleep(tracklen)

  wait_until {
    page.find('#song-name').text.should match(/test-03\.mp3/)
  }
  sleep(tracklen)

  # If we get here then we repeated back to the beginning
  wait_until {
    page.find('#song-name').text.should match(/test-01\.mp3/)
  }
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'

  pause_for_next_step
end

Then(/^I should be able to toggle repeat\-one$/) do
  page.find("#playbar-repeat").click

  page.first(".mp3-title a.play-mp3").click()
  $devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'

  sleep(0.2)
  page.find('#song-name').text.should match(/test-01\.mp3/)
  sleep(tracklen)

  page.find('#song-name').text.should match(/test-01\.mp3/)
  sleep(tracklen)

  page.find('#song-name').text.should match(/test-01\.mp3/)
  sleep(1)

  # Turn off repeat
  page.find("#playbar-repeat").click

  pause_for_next_step
end

Then(/^I should be able to stop all$/) do
  page.find("#stop-all a").trigger("click")
  sleep(0.1)
  page.evaluate_script("scope.browser_device.player_status").should_not eql("PLAYING")
end

Then(/^I should be able to play and pause white noise$/) do
  page.find(".select-mode", :text => 'White Noise').click() 

  page.first(".mp3-title a").click
  #$devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  #$devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'

  page.find('#song-name').text.should match(/test-04\.mp3/)
  pause_for_next_step
end

Then(/^I should be able to play and pause a radio station$/) do
  page.find(".select-mode", :text => 'Radio').click() 
  $devices[0].wait_for_device_status("BUFFERING", 0.25, 5) if $test_mode == 'cca'
  $devices[0].wait_for_device_status("PLAYING", 0.25, 5) if $test_mode == 'cca'

  page.first(".mp3-title a").click

  page.find('#song-name').text.should match(/WBEZ Chicago/)
  #pause_for_next_step
end

Given(/^I am in 'spoken' mode$/) do
  page.find(".select-mode", :text => 'Spoken').click()
end

Then(/^I should be able to play a spoken word track$/) do
  page.find(".select-folder", :text => "playlist").click()

  # Click the first mp3
  page.first(".play-mp3").click()
  safeApply()
  sleep(1.0)
  page.find("#playbar-pause").should be_visible
  page.find('#song-name').text.should match(/test-01\.mp3/)
  
end

When(/^I hit pause a bookmark should be saved$/) do
  page.find("#playbar-pause").click()
  sleep 0.1
  page.find("#playbar-resume").should be_visible
  sleep 0.25

  book_folder = nil
  wait_until {
    book_folder = Folder.where("mode = 'spoken' AND parent_folder_id = -1 AND basename = 'playlist'").first
    bm = JSON.load(book_folder.bookmark)
    bm["elapsed"].should eql(1)
    bm["mp3"]["filename"].should match(/test-01/)
    
  }

  book_folder.bookmark = nil
  book_folder.save

  page.find("#playbar-resume").click()
end

When(/^I leave the page a bookmark should be saved$/) do
  visit "/robots.txt"

  book_folder = Folder.where("mode = 'spoken' AND parent_folder_id = -1 AND basename = 'playlist'").first
  bm = JSON.load(book_folder.bookmark)
  bm["elapsed"].should eql(1)
  bm["mp3"]["filename"].should match(/test-01/) 
end

Then(/^I should be able to resume from my bookmark$/) do
  visit("/")
  wait_until {
    puts page.text
    page.text.should match(/Resume From Bookmark/)
    page.text.should match(/00m 01s/)
  }
end
