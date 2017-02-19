# The crono server is necessary to be able to schedule presets to run
RAILS_ENV=development bundle exec crono stop
RAILS_ENV=development bundle exec crono start &

# Start the server bound to all IPs (so you can stream mp3s from other machines) on port 4040
rails s -b 0.0.0.0 -p 4040
