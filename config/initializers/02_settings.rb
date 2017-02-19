
$settings = YAML.load_file(Rails.root + 'config/settings.yml')
$settings['port'] ||= 4040