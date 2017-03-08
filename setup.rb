require 'socket'
require 'colorize'
require 'yaml'
require 'highline'

line = "\n================================================================================\n\n"

def is_numeric?(obj) 
   obj.to_s.match(/^\d+$/) == nil ? false : true
end

if File.exist? 'config/settings.yml'
  settings = YAML.load_file('config/settings.yml')
else
  settings = {
    'login_username' => '',
    'login_password' => '',
    'port' => 4040,
    'ddns_hostname' => '',
    'ddns_update' => '',
    'menu' => [ 'music', 'spoken', 'white-noise', 'radio', 'presets', 'settings' ]
  }
end

cli = HighLine.new


puts line.colorize(:blue)
puts "Welcome to Humble Audio Server Setup"

puts "\nStep 1 of 4: Menu Items".colorize(:light_blue)
puts "\nThis populates the leftmost column in the UI."
puts "\nIf you will have MP3s of the given type, enter Y. If not, enter N.\n"
puts "\nNote: you can always re-run setup later to change menu items"

items_all = [ 'music', 'spoken', 'white-noise', 'radio', 'presets', 'settings' ]
captions = {
  'music' => "Music MP3s",
  'spoken' => "Spoken word (audio books, podcasts etc)",
  'white-noise' => "White noise tracks",
  'radio' => "Radio stations",
  'presets' => "Chromecast Presets (enable if you have Chromecast Audios)",
  'settings' => "Settings item"
}
arr = []
items_all.each do |itm|
  val = (settings['menu'].include?(itm) ? 'Y' : 'N')
  inp = cli.ask(captions[itm] + ":") { |q| q.default = val }
  if inp && inp.upcase == 'Y'
    arr.push(itm)
  end
end
settings['menu'] = arr

puts "\nStep 2 of 4: Authentication".colorize(:light_blue)
puts "\nIf you want to require users to login, set both username and password. If not, leave them blank."
puts "\nIf you want to make your server internet accessible, it is ABSURDLY HIGHLY RECOMMENDED that you require a login.".colorize(:red)
puts "\nUsername and password must be alphanumeric: no spaces, !, ;, quotes or or other characters"
puts "\nJust hit enter to leave the default setting or use 'n/a' (without quotes) to clear the value.\n\n"

inp = "."
while !inp.match(/^[a-zA-Z0-9]*$/)
  inp = cli.ask("Username (or n/a):  ") { |q| q.default = settings['login_username'] }
  inp = '' if inp.downcase() == 'n/a'
  if !inp.match(/^[a-zA-Z0-9]*$/)
    puts "Sorry, that's an invalid username"
  end
end
settings["login_username"] = inp

if settings["login_username"] != ''
  inp = "."
  while !inp.match(/^[a-zA-Z0-9]*$/)
    inp = cli.ask("Password:  ") { |q| q.default = settings['login_password'] }
    inp = '' if inp.downcase() == 'n/a'
    if !inp.match(/^[a-zA-Z0-9]*$/)
      puts "Sorry, that's an invalid password"
    end
  end
  settings["login_password"] = inp
end

puts line.colorize(:blue)
puts ("\nStep 3 of 4: Set a Port").colorize(:light_blue)

puts "\nIf you set port to 80, you can get to the server from: http://your.ip.address. If not, the URL will require a port at the end: http://your.ip.address:4040"
puts "\nThe latter is recommended if you're exposing your server to the internet as it makes it less likely for your server to fall to automated hacking tools."
puts "\nRecommended ports: 4040, 8011, 10000. Prohibited ports: 22, 139, 445, 3306, 6379\n\n"

puts settings.inspect

inp = '.'
while !is_numeric?(inp)
  inp = cli.ask("Port:  ") { |q| q.default = settings['port'].to_s }

  if is_numeric?(inp)
    if [ 22, 139, 445, 3306, 6379 ].include? inp.to_i
      puts "Sorry, that's a prohibited port"
      inp = nil
    end
    if inp.to_f > 65535
      puts "Sorry, the max port is 65535"
      inp = nil
    end
  elsif inp == ''
    inp = settings['port']
  end
end
settings['port'] = inp

puts line.colorize(:blue)
puts "\nStep 4 of 4: Expose your server to the internet (optional)".colorize(:light_blue)

puts "\nIf you expose your server to the internet, you'll be able to use it outside your home network, e.g.: from a cell phone in the car, from the office, etc.

If that's not a requirement, leave these values blank.

If it *is* what you want, getting it working is a bit tricky. You must either:

(1) Set up a free or paid dynamic DNS server (for free servers the author recommends www.duckdns.org or freedns.afraid.org)

See also: https://www.google.com/search?q=dynamic+dns+free+site%3Areddit.com

or

(2) Buy a domain name and point it to your home computer by setting an A record (~ $10 / year for the domain).
The author personally uses namecheap.com, here's a howto from them:
https://www.namecheap.com/support/knowledgebase/article.aspx/319/78/how-can-i-setup-an-a-address-record-for-my-domain

If you have either of the above, paste the hostname below without the http://  Examples: flerg.duckdns.org, humble.mydomain.net

Note: if you set a hostname and Humble can't connect to it, the server will not start.

"

inp = cli.ask("Hostname:  ") { |q| q.default = settings['ddns_hostname'] }
if inp.downcase() == 'n/a'
  settings['ddns_hostname'] = ''
  settings['ddns_update'] = ''
else
  settings['ddns_hostname'] = inp
end

if settings['ddns_hostname'] != ''
  ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
  if ip.nil?
    raise "Error 1000: Could not find a local IP address. Is this machine connected to a local network?"
  end
  ip = ip.ip_address

  puts line.colorize(:blue)
  puts "\n\nIf you chose option (1) above (dynamic DNS hostname), you can optionally let Humble Media Server update the host's IP address for you every 30 minutes (in case your ISP changes it and the server stops working)

If that's what you want, paste your 'update URL' here. For example, for duckdns.org log in and go to the 'install' page.

It will be about halfway down the page and will look like this:

https://www.duckdns.org/update?domains=myhumbleserver&token=9f16afcc-89e2-4b83-b146-4e4bc0777ee2&ip=

If you don't set an update URL, and aren't otherwise updating your IP with your dynamic DNS provider, your server might stop working randomly when your IP changes.

If you chose option (2) above (domain name) then just leave this blank.

"
  inp = cli.ask("Update URL:  ") { |q| q.default = settings['ddns_update'] }
  inp = '' if inp.downcase() == 'n/a'
  settings['ddns_update'] = inp

  puts line.colorize(:blue)
  puts "Now comes the tricky part.  Please set up port forwarding on your router:

http://www.wikihow.com/Set-Up-Port-Forwarding-on-a-Router

You should be forwarding only port #{settings['port']} to IP address: #{ip}

When this is done, type OK below.

"
  inp = ''
  while inp != 'OK'
    inp = gets.chomp
  end
end

puts line.colorize(:blue)

str = "
port: #{settings['port']}

# If set, makes this server available over the internet. Can be either a DDNS host or a domain name.
ddns_hostname: #{settings['ddns_hostname']}

# If set, the server will curl this address every 30 minutes to update your IP with your DDNS provider.
ddns_update: #{settings['ddns_update']}

# If a password is set the app will require the user log in.
# This is recommended if you're serving out to the internet -- otherwise some random script kiddie in Belarus might blast heavy metal on all your chromecasts at 3AM.
# Username and password must be alphanumeric: no spaces, !, ;, quotes or or other characters
login_username: #{settings['login_username']}
login_password: #{settings['login_password']}

menu:
"
settings['menu'].each do |itm|
  str += "  - #{itm}\n"
end

File.write("config/settings.yml", str)

puts "Setup complete! Starting server..."