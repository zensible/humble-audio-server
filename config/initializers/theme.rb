
$theme = YAML.load_file(Rails.root + 'config/theme.yml')

$theme = $theme[$theme['theme']]

