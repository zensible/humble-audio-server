require 'thread'
require 'socket'

$semaphore = Mutex.new # See: app/models/py_chromecast.rb
$threads = {}
$devices = [] # Global array of devices

# Initialize chromecast API and get a list of available cast devices

unless ENV["RAILS_ENV"].nil? || ENV["RAILS_ENV"] == 'test' || !!@rake # Don't run for rake tasks, tests etc
  PyChromecast.init()

end

# Set audio directory and $http_address
$audio_dir = Rails.root.join('public', 'audio')

begin

  ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
  ip = ip.ip_address

  port = Rails::Server.new.options[:Port]
  $http_address = "http://#{ip}:#{port}"

  puts "

================================
Startup successful! This multiroom audio server is available at this address:

#{$http_address}
================================

  "
rescue NameError => e
  # We're running a rake or other task, Rails::Server isn't available
end

# Forgot what's playing when the server stops, it probably won't be correct when it starts up again
at_exit { 
  $redis.del("state_shared")
}
