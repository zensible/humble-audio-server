module PythonHelper

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
      next if cmd.blank? || cmd.gsub(/\s+/, "").blank?
      cmd = cmd.gsub(/^\s+/, '')
      puts "= RUN: [#{cmd}]"
      $pyin.puts cmd
      $pyout.expect(">>>") do |result|
        retval = parse_result(cmd, result[0])
        puts "= result1: ***#{retval}***"
      end
    end
    return retval
  end

end