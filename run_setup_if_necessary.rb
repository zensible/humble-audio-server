@run_setup = false

if File.exist? "config/settings.yml"
  resp = `read -t 3 -p "Press 's' then ENTER in the next 3 seconds to enter setup...\n" -s VAR; echo $VAR`
  if resp.match(/s/)
    @run_setup = true
  end
else
  @run_setup = true
end

puts ""
if @run_setup
  load 'setup.rb'
end