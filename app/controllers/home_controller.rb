class HomeController < ApplicationController
  require 'expect'
  require 'pty'

  def home
    def parse_result(cmd, str)
      # Trim off trailing >>> and preceding command so we return only output
      str = str.gsub(/\r*\n>>>/, "")
      str = str.gsub(/\s*#{Regexp.escape(cmd)}\r*\n/, "")

      #abort "#{cmd} - [#{str}]" if str.match(/Justin/)
      #lines = str.split(/(\r)\n/)
      #output = []
      #lines.each do |line|
      #  puts "== OUT: #{line}"
      #end
      return str
    end

    def run_py(str)
      retval = nil
      str.split(/\n/).each do |cmd|
        next if cmd.blank?
        puts "= RUN: [#{cmd}]"
        $pyin.puts cmd
        $pyout.expect(">>>") do |result|
          retval = parse_result(cmd, result[0])
          puts "= result1: ***#{retval}***"
        end
      end
      return retval
    end

    # Wait until terminal is ready

    @init = "
from __future__ import print_function
import time
import pychromecast
import json
"

@get_devices = "
chromecasts = pychromecast.get_chromecasts()
arr = [cc.device.friendly_name for cc in chromecasts]
print(json.dumps(arr))
"
    run_py(@init)

    @devices = JSON.parse(run_py(@get_devices))

  end

  def template
    template_name = params[:template_name]

    render "home/#{template_name}", locals: {  }, :layout => nil
  end

end
