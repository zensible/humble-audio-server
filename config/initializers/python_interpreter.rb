include PythonHelper

#RubyPython.start
require 'expect'
require 'pty'

`pkill -f python`
arr = PTY.spawn("cd py && python")
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

run_py(init)

PythonHelper.refresh_devices()

