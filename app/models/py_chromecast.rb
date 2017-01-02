class PyChromecast

  require 'expect'
  require 'pty'

  # Initializes the pychromecast API.
  # 
  # In order to make this python lib place nice with ruby/rails, I had to do something tricky and odd, though it has proven to be rock solid.
  #
  # What's happening is:
  # 
  # 1. We go to the pychromecast directory and start a python REPL interpreter
  # 2. By starting this process, we receive STDIN, STDOUT handlers and its PID
  # 3. By throwing code at STDIN and waiting for '>>>' from STDOUT (python's 'ready-for-next-input' signal), we can effectively run python code from within ruby
  #
  # The reason for this is, as of this writing pychromecast is by far the best library for interacting with casts -- nothing in ruby-land can compare.
  #
  def self.init()
    arr = PTY.spawn("cd pychromecast && python")

    $pyout = arr[0]
    $pyin = arr[1]
    $pid = arr[2]

    # Wait until terminal is ready
    $pyout.expect(">>>")

    # Import necessary libs
    init = "
from __future__ import print_function
import time
import pychromecast
import json
    "

    self.run(init)

    Device.refresh()
  end

  def self.run(str)
    retval = nil
    str.split(/\n/).each do |cmd|
      next if cmd.blank? || cmd.gsub(/\s+/, "").blank?
      cmd = cmd.gsub(/^\s+/, '')
      puts "= RUN: [#{cmd}]"
      STDOUT.flush
      $pyin.puts cmd
      #sleep(0.01)
      $pyout.expect(">>>") do |result|
        retval = parse_result(cmd, result[0])
        puts "= result1: ***#{retval}***"
        STDOUT.flush
      end
    end
    return retval
  end  

  def self.parse_result(cmd, str)
    #puts "BEFORE: [[#{str}]] cmd: [[#{cmd}]]"
    # Trim off trailing >>> and preceding command so we return only output
    str = str.gsub(/\r*\n>>>/, "")
    if str.match(/#{Regexp.escape('Traceback (most recent call last)')}/)
    end
    str = str.gsub(/^\s?#{Regexp.escape(cmd)}/, "")
    str = str.gsub(/^\r?/, "")
    str = str.gsub(/^\n?/, "")
    #puts "AFTER: [[#{str}]]"
    return str
  end

end