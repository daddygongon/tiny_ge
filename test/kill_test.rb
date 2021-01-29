require 'command_line/global'

res = command_line('ps -ux|grep test.sh')
res.stdout.split("\n").each do |line|
  p pid = line.match(/\s(\d+)\s/)[1].to_i
  command_line("kill -9 #{pid}")
end
