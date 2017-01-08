require 'thread'
$semaphore = Mutex.new

# Don't run for rake tasks, tests etc
unless ENV["RAILS_ENV"].nil? || ENV["RAILS_ENV"] == 'test' || !!@rake
  PyChromecast.init()
end

at_exit { 
  $redis.del("cur_cast")
  $redis.del("state_shared")
}

