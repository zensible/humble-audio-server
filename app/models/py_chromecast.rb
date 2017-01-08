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

  def self.run(str, strip_leading_spaces = true, split_lines = true)
    retval = nil
    $semaphore.synchronize { # So race conditions don't pop up when casting to multiple devices
      if split_lines
        arr = str.split(/\n/)
      else
        arr = [ str ]
      end
      arr.each do |cmd|
        next if cmd.blank? || cmd.gsub(/\s+/, "").blank?
        cmd = cmd.gsub(/^\s+/, '') if strip_leading_spaces
        puts "= RUN: [#{cmd}]\n\n"
        STDOUT.flush
        $pyout.flush
        $pyin.puts cmd
        $pyin.flush
        $pyout.flush
        #sleep(0.01)
        $pyout.expect(">>>") do |result|
          $pyout.flush
          retval = parse_result(cmd, result[0])
        $pyout.flush
          puts "= result1: ***#{retval}***\n\n"
          STDOUT.flush
        end
      end
    }
    return retval
  end  

  def self.parse_result(cmd, str)
    #puts "BEFORE: [[#{str}]] cmd: [[#{cmd}]]"
    # Trim off trailing >>> and preceding command so we return only output
    str = str.gsub(/\r?\n>>>/, "")
    if str.match(/#{Regexp.escape('Traceback (most recent call last)')}/)
      # ToDo: deal with errors
    end
    str = str.gsub(/^\s?#{Regexp.escape(cmd)}/, "")
    str = str.gsub(/^\r?/, "")
    str = str.gsub(/^\n?/, "")
    #puts "AFTER: [[#{str}]]"
    return str
  end

end