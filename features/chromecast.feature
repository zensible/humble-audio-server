@logged_in @javascript @music_exists
Feature: Chromecasts

Scenario: play music, pause, next/prev, repeat/shuffle, stop, play white noise, play radio
  Given I am in 'music' mode
  And I select a chromecast device
  Then I should be able to play a music playlist
  And I should be able to pause and resume an mp3
  And I should be able to use next and prev
  #And I should be able to seek   # Note: too difficult to test w/ CCA and 2-second test mp3s
  And I should be able to toggle repeat-all
  And I should be able to toggle repeat-one
  And I should be able to toggle shuffle
  And I should be able to stop all
  And I should be able to play and pause white noise
  And I should be able to play and pause a radio station

Scenario: bookmarks
  Given I am in 'spoken' mode
  And I select a chromecast device
  Then I should be able to play a spoken word track
  When I hit pause a bookmark should be saved
  When I leave the page a bookmark should be saved
  And I should be able to resume from my bookmark

Scenario: presets
  Given I am in 'music' mode
  And I select a chromecast device
  Then I should be able to play a music playlist
  And I should be able to save the current output as a Preset
  And I should be able to update the preset with a start/stop time
  And the preset should trigger at the appropriate time
  And the preset should stop at the appropriate time
  And the preset should trigger at the appropriate time
