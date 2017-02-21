
$settings = YAML.load_file(Rails.root + 'config/settings.yml')

# Set some sensible defaults
$settings['port'] ||= 4040
$settings['ddns_hostname'] ||= ""
$settings['ddns_update'] ||= ""
