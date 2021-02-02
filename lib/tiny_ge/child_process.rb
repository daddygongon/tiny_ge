require 'command_line/global'

module ChildProcess
  def find_child_process_recursively(pid)
    $data.each do |item|
      next if item==nil
      if item[4] == pid
        puts item[0]
        $pids << item[3]
        find_child_process_recursively(item[3])
      end
    end
    return nil
  end

  def kill_all_child_process(pid)
    #pid = ARGV[0] || '13931'

    # store jobs in $data
    $data = command_line('ps -xal').stdout.split("\n").inject([]) do |dd, line|
      dd << line.match(/^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(.+)/)
    end

    $pids = [pid]
    find_child_process_recursively(pid)

    $pids.uniq.each do |pid|
      command_line "kill -9 #{pid}"
    end
  end
end
