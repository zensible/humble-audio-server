
$settings = YAML.load_file(Rails.root + 'config/' + (Rails.env.test? ? 'test.yml' : 'settings.yml'))

# Set some sensible defaults
$settings['port'] ||= 4040
$settings['ddns_hostname'] ||= ""
$settings['ddns_update'] ||= ""
