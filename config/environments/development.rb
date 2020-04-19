Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  if $0 == 'bin/rails' # Don't run for rake tasks, tests etc
    begin
      ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
      ip = ip.ip_address
      host = "#{ip}:#{Rails::Server.new.options[:Port]}"
    rescue NameError => e
      puts "Error: couldn't get hostname for websockets, using localhost"
      host = "localhost"
    end
    host = "ws://#{host}/cable"
    host = ENV.fetch('WS_HOST_OVERRIDE', host)
    # Docker hack
    puts "== Actioncable host: #{host}"
    config.action_cable.url = host
    config.action_cable.allowed_request_origins = [/http:\/\/*/, /https:\/\/*/]
    config.action_cable.disable_request_forgery_protection = true
  end

  # Enable/disable caching. By default caching is disabled.
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.assets.cache_store = :null_store  # Disables the Asset cache
  config.sass.cache = false  # Disable the SASS compiler cache
  config.assets.cache = false

  config.assets.configure do |env|
    env.cache = ActiveSupport::Cache.lookup_store(:null_store)
  end

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Change to :debug to see all logs. Generally useful only for debugging the ruby code itself.
  config.log_level = :debug

end
