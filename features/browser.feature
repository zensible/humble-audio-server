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

Scenario: spoken
  Given I am in 'spoken' mode
  When I hit pause
  Then a bookmark should be saved
  When I leave the page
  Then a bookmark should be saved
