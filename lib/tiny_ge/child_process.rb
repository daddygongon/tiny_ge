require 'command_line/global'

module ChildProcess
  def find_child_process_recursively(pid)
    $data.each do |item|
      next if item==nil
       if item[4].to_i == pid.to_i
        $pids << item[3].to_i
        find_child_process_recursively(item[3].to_i)
      end
    end
    return nil
  end

  def kill_all_child_process(pid)
    p $pids = [pid]
    # store jobs in $data
    $data = command_line('ps -xal').stdout.split("\n").inject([]) do |dd, line|
      dd << line.match(/^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(.+)/)
      # stored in String
    end

    find_child_process_recursively(pid)
    p $pids
    $pids.uniq.each do |pid|
      p command = "kill -9 #{pid}"
      command_line command
    end
  end
end
