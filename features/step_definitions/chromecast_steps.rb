
Given(/^I select a chromecast device$/) do
  sleep 1

  $test_mode = 'cca'

  page.find(".select-cast", :text => "Test-CCA").click()
  safeApply()
  sleep(0.1)
  page.should have_css(".select-cast span.selected")
end

Then(/^I should be able to save the current output as a Preset$/) do
end

Then(/^I should be able to update the preset with a start\/stop time$/) do
end

Then(/^the preset should trigger at the appropriate time$/) do
end

Then(/^the preset should stop at the appropriate time$/) do
end
