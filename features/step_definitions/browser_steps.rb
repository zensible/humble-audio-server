Given(/^I am in 'music' mode$/) do
  page.find(".select-mode", :text => 'Music').click()
end

Then(/^I should be able to play a music playlist$/) do
  page.find(".select-folder", :text => "playlist").click()
  page.first(".play-mp3").click()
  sleep(0.5)
  page.find(".mp3-playing .play-button").should be_visible
  page.first("#media-selector .play-button").should be_visible
  page.find("#back-button").click()
  page.first(".folder-playing .play-button").should be_visible
  page.find("#browser-device .play-button").should be_visible
end

Then(/^I should be able to pause and resume an mp3$/) do
  page.find("#playbar-pause").click()
  page.find("#playbar-resume").should be_visible

  page.find("#playbar-resume").click()
  page.find("#playbar-pause").should be_visible
end

Then(/^I should be able to use next and prev$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to seek$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to stop all$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to toggle shuffle$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to toggle repeat\-all$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to toggle repeat\-one$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
