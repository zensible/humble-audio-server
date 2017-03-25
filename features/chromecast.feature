@logged_in @javascript @music_exists
Feature: Chromecasts

Scenario: play music, pause, next/prev, repeat/shuffle, stop, play white noise, play radio
  Given I am in 'music' mode
  And I select a chromecast device
  Then I should be able to play a music playlist
  And I should be able to pause and resume an mp3
  And I should be able to use next and prev
  And I should be able to seek
  And I should be able to toggle repeat-all (CCA)
  And I should be able to toggle repeat-one (CCA)
  And I should be able to toggle shuffle (CCA)
  And I should be able to stop all (CCA)
  And I should be able to play and pause white noise (CCA)
  And I should be able to play and pause a radio station (CCA)

Scenario: bookmarks
  Given I am in 'spoken' mode (CCA)
  Then I should be able to play a spoken word track (CCA)
  When I hit pause a bookmark should be saved (CCA)
  When I leave the page a bookmark should be saved (CCA)
  And I should be able to resume from my bookmark (CCA)
