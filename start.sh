ruby run_setup_if_necessary.rb

. lib/parse_yaml.sh

eval $(parse_yaml ./config/settings.yml "settings_")

# The crono server is necessary to be able to schedule presets to run
echo "= INIT 1 of 4: Starting crono server..."
RAILS_ENV=development bundle exec crono restart
echo "= Done!"

# Start the server bound to all IPs (so you can stream mp3s from other machines) on port specified in config/settings.yml
if [ "$settings_port" -le "1024" ]; then
  export rvmsudo_secure_path=1
  rvmsudo rails s -b 0.0.0.0 -p $settings_port
else
  rails s -b 0.0.0.0 -p $settings_port
fi
