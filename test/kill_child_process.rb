require 'command_line/global'

res = command_line('ps -xal')

pid = '13931'
data = []
res.stdout.split("\n").each do |line|
  data << line.match(/^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(.+)/)
end

pids = [pid]
data.each do |item|
  next if item==nil
  if item[4] == pid
    puts item[0]
    pid = item[3]
    pids << pid
  end
end
pid = pids[-2]
data.each do |item|
  next if item==nil
  if item[4] == pid
    puts item[0]
    pids << item[3]
  end
end

pids.uniq.each do |pid|
  puts "kill -9 #{pid}"
end
