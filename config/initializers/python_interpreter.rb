
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
