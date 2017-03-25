
Given(/^I select a chromecast device$/) do
  screenie()

  page.find(".select-cast", :text => "Bedroom-Guest").click()
  safeApply()
  sleep(0.1)
  page.should have_css(".select-cast span.selected")
end

Then(/^I should be able to play a music playlist \(CCA\)$/) do
  
end

Then(/^I should be able to pause and resume an mp(\d+) \(CCA\)$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to use next and prev \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to seek \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to toggle repeat\-all \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to toggle repeat\-one \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to toggle shuffle \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to stop all \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to play and pause white noise \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to play and pause a radio station \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^I am in 'spoken' mode \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be able to play a spoken word track \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^I hit pause a bookmark should be saved \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^I leave the page a bookmark should be saved \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^I should be able to resume from my bookmark \(CCA\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

