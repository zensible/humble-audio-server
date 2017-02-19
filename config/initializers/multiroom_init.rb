require 'thread'
require 'socket'
require 'timeout'

if ENV['DEBUG'] == 'true'
  Rails.logger.level = 0
end

$semaphore = Mutex.new # See: app/models/py_chromecast.rb
$threads = {}
$devices = [] # Global array of devices

if $0 == 'bin/rails' # Don't run for rake tasks, tests etc

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
================================

Initializing chromecast API and getting a list of available cast devices...

"

  PyChromecast.init()
  Device.refresh()

  # Set audio directory and $http_address
  $audio_dir = Rails.root.join('public', 'audio')

  ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
  if ip.nil?
    raise "Error 1000: Could not find a local IP address. Is this machine connected to a local network?"
  end
  ip = ip.ip_address
  $ip_address = ip
  $port = $settings['port']

  $http_address_local = "http://#{ip}:#{$port}"

  $has_ddns = false
  if $settings['ddns_hostname']
    $has_ddns = true
    $http_address_ddns = "http://#{$settings['ddns_hostname']}:#{$port}"
  end

  # Wait up to 5 seconds for code block to return true
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

  def exec_with_timeout(cmd, timeout)
    pid = Process.spawn(cmd, {[:err,:out] => :close, :pgroup => true})
    begin
      Timeout.timeout(timeout) do
        Process.waitpid(pid, 0)
        $?.exitstatus == 0
      end
    rescue Timeout::Error
      Process.kill(15, -Process.getpgid(pid))
      false
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
    puts "\n\n== Server is available on the local network at this address:\n#{$http_address_local}\n\n"

    if $has_ddns
      # Since local server is up, internet-based server should now work

      # Wait up to 5 seconds for DDNS-based server to come online
      max_timeout = 5 # If your web server can't return a tiny text file in that amount of time it will never work for streaming
      if `curl -s --max-time #{max_timeout} --connect-timeout #{max_timeout} #{$http_address_ddns}3/test.txt`.match(/Your server works!/)
        puts "\n\n== Server is online over the internet at this address:\n#{$http_address_ddns}\n\n"
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
    end

    puts "================================"
  }
end

# Forget what's playing when the server stops, it probably won't be correct when it starts up again
at_exit { 
  $redis.del("state_shared")
}

