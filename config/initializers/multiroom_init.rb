require 'thread'
require 'socket'
require 'timeout'

if ENV['DEBUG'] == 'true'
  Rails.logger.level = 0
end

$semaphore = Mutex.new # See: app/models/py_chromecast.rb
$threads = {}
$devices = [] # Global array of devices

$has_chromecasts = false

$curl_basic_auth = ""
if $settings['login_username'] && $settings['login_password']
  $curl_basic_auth = "-u #{$settings['login_username']}:#{$settings['login_password']}"
end

# Set audio directory and $http_address
$audio_dir = Rails.root.join('public', (Rails.env.test? ? 'test' : 'audio'))
if $0 == 'bin/rails' || $0.match(/cucumber/) # Don't run for rake tasks, tests etc

  if !`curl --version`.match(/^curl \d/)
    puts "=====
WARNING: 'curl' program not found. If it's not present, two features won't work: preset scheduler and dynamic dns

Try installing and restarting the server:

https://www.google.com/search?q=how+install+curl+mac
https://www.google.com/search?q=how+install+curl+ubuntu

======
"
  end

  puts "

= INIT 2 of 4: Initializing chromecast API and getting a list of available cast devices...

"

  #PyChromecast.init()
  #Device.refresh()

  ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
  if ip.nil?
    raise "Error 1000: Could not find a local IP address. Is this machine connected to a local network?"
  end
  ip = ip.ip_address
  $ip_address = ip
  $port = Rails.env.test? ? 65501 : $settings['port']

  if $port == 80
    $http_address_local = "http://#{ip}"
  else
    $http_address_local = "http://#{ip}:#{$port}"
  end

  $http_address_local = ENV.fetch('WEB_HOST_OVERRIDE', $http_address_local)

  $has_ddns = false
  if !$settings['ddns_hostname'].blank?
    $has_ddns = true
    if $port == 80
      $http_address_ddns = "http://#{$settings['ddns_hostname']}"
    else
      $http_address_ddns = "http://#{$settings['ddns_hostname']}:#{$port}"
    end
  end

  def wait_until(max=5, wait_time=0.15)
    start = Time.now.to_f
    begin
      yield
    rescue Exception => ex
      if (Time.now - start).to_f > max
        puts "== waited max #{max} seconds" if ENV['VERBOSE'] == 'true'
        raise
      else
        sleep(wait_time)
        retry
      end
    end
  end

  Thread.new {
    puts "Startup successful!"

    # Wait up to 15 seconds for local server to come online
    wait_until(15, 0.5) {
      if !`curl -s #{$http_address_local}/test.txt`.match(/Your server works!/)
        raise "Error 1001: Could not connect to local server"
      end
    }
    puts "\n\n= INIT 3 of 4: Server is available on the local network"

    if $has_ddns
      # Since local server is up, internet-based server should now work

      # Wait up to 5 seconds for DDNS-based server to come online
      max_timeout = 5 # If your web server can't return a tiny text file in that amount of time it will never work for streaming
      if `curl -s --max-time #{max_timeout} --connect-timeout #{max_timeout} #{$http_address_ddns}/test.txt`.match(/Your server works!/)
        puts "\n\n= INIT 4 of 4: Server is online over the internet\n\n"

        if $settings['ddns_update'].match(/http/)
          puts "Scheduling DDNS IP address update for every 30 minutes"
        end
      else
        puts "==== WARNING: This server is NOT available over the internet, only over the local network.

Server is unreachable after #{max_timeout} seconds: '#{$http_address_ddns}'

Are you sure your dynamic dns service or domain is working correctly?

Please:

1. Make sure this computer has a static IP of #{$ip_address}
2. Try updating your internet IP address with the DDNS provider
3. Make sure your router is port forwarding #{$settings['port']} to #{$ip_address}. http://www.wikihow.com/Set-Up-Port-Forwarding-on-a-Router

The author recommends duckdns.org as a reliable free DDNS provider."
      end
    else
      puts "\n\n= INIT 4 of 4 skipped: No DDNS server configured in settings.yml. Streaming will be available only on the local network."
    end

    Preset.update_crono

    puts "================================"
    puts "\n"
    if $has_chromecasts
      puts "#{$devices.length} Chromecast Audios / Groups available"
    else
      puts "No chromecasts available"
    end
    puts "Streaming to browser on local network enabled: #{$http_address_local}"
    if $has_ddns
      puts "Streaming to browser over the internet enabled: #{$http_address_ddns}"
    else
      puts "Streaming to browser over the internet not enabled"
    end
    if $settings['login_username'] && $settings['login_password']
      puts "Authorization is required. Username: #{$settings['login_username']}"
    else
      puts "Authorization is NOT required"
    end

    puts "\nAll systems go! Get streamin'!\n\n"
  }
end
