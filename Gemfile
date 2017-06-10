source 'https://rubygems.org'

ruby "2.3.1"

gem 'puma', '3.8.0'
gem 'rails', '~> 5.0.1'

gem 'mysql2', '~> 0.3.18'
gem 'redis'

gem 'haml'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', '0.12.0'
gem 'libv8'
gem 'jquery-rails'
gem 'jbuilder', '~> 2.5'
gem 'bcrypt', '~> 3.1.7'

gem 'rest-client'
gem 'colorize'

# For use in preset scheduling
gem 'crono'
gem 'daemons'

# Reads mp3 id3 tags
gem 'taglib-ruby'


group :development, :test do
  gem 'byebug', platform: :mri
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'webmock'
  gem 'capybara'
  gem 'cucumber'
  gem 'cucumber-rails', '>= 1.3.1', :require=>false
  gem 'capybara-screenshot'
  gem 'poltergeist'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'json_spec'
  gem 'data_spec', '>= 0.0.2'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
