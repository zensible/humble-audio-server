@logged_in @javascript @music_exists
Feature: Browser

Scenario: music
  Given I am in 'music' mode
  Then I should be able to play a music playlist
  And I should be able to pause and resume an mp3
  And I should be able to use next and prev
  And I should be able to seek
  And I should be able to toggle repeat-all
  And I should be able to toggle repeat-one
  And I should be able to toggle shuffle
  And I should be able to stop all
  And I should be able to play and pause white noise
  And I should be able to play and pause a radio station

Scenario: bookmarks
  Given I am in 'spoken' mode
  Then I should be able to play a spoken word track
  When I hit pause a bookmark should be saved
  When I leave the page a bookmark should be saved
  And I should be able to resume from my bookmark
