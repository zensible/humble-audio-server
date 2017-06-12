
Given(/^I select a chromecast device$/) do

  puts "
================================================================================================
These tests talk to an actual Chromecast Audio

In order for them to work, follow these steps:

1. Start the server normally and play something with your test device.
2. Set the test_cca_name and test_cca_id in config/test.yml
3. STOP the dev server (it will cause the tests to fail)
4. Run the tests:

DEBUG=true cucumber features/chromecast.feature

Steps 1 and 4 prevent getting stuck in an 'UNKNOWN' status for your test device

Note: you may have to re-run the tests if they fail. There are some weird timing problems if it's hitting the test CCA for the first time.
================================================================================================
"
  sleep 1

  $test_mode = 'cca'

  page.find(".select-cast", :text => $settings['test_cca_name']).click()
  safeApply()
  sleep(0.1)
  page.should have_css(".select-cast span.selected")
end

Then(/^I should be able to play a music playlist \(CCA\)$/) do
  
end

