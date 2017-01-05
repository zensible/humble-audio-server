$settings = YAML.load_file(Rails.root + 'config/settings.yml')

$audio_dir = Rails.root.join('public', 'audio')
