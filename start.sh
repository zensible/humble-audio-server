ruby run_setup_if_necessary.rb

. lib/parse_yaml.sh

eval $(parse_yaml ./config/settings.yml "settings_")

# The crono server is necessary to be able to schedule presets to run
if [ ! -f /tmp/foo.txt ]; then
  echo "" > config/cronotab.rb
fi

# Start the server bound to all IPs (so you can stream mp3s from other machines) on port specified in config/settings.yml
if [ "$settings_port" -le "1024" ]; then
  rvmsudo rails s -b 0.0.0.0 -p $settings_port
else
  rails s -b 0.0.0.0 -p $settings_port
fi