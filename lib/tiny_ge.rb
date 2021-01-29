require "tiny_ge/version"
require 'yaml'
require 'thor'
require 'command_line/global'

#VE_SUBMIT_JOBS_FILE = File.join(ENV['HOME'],".ve_submit_jobs.txt")
VE_TEST_FILE = File.join(ENV['HOME'],".tge_test_jobs.txt")

class TGE
  def initialize(q_file=VE_TEST_FILE)
    @q_file = VE_TEST_FILE
    @data = YAML.load(File.read(@q_file))
  end
  def add_job(pid, shell_path)
    @data << {pid: pid, status: 'waiting', shell_path: shell_path, submit: Time.now, start: nil}
    File.write(VE_TEST_FILE, YAML.dump(@data))
    p shell_path
    shell_file = "./test.sh"
    shell_script = <<-EOS
#!/bin/sh
while ! qsub #{pid}; do
  sleep 10
done
echo "hello world"
sleep 30
  qfinish #{pid}
    EOS
    File.write(shell_file, shell_script)
    command_line("chmod u+x #{shell_file}")
    p pid = spawn(shell_file, :out => "test.out", :err => "test.err")
    Process.detach(pid)
    puts "#{pid} is added on the queue."
  end

  def change_job_status(pid, status)
    @data.each do |job, i|
      if job[:pid] == pid
        job[:status] = status
        job[:start] = Time.now if status == 'running'
        File.write(VE_TEST_FILE, YAML.dump(@data))
        break
      end
    end
  end

  def qfinish(pid)
    change_job_status(pid, 'finished')
    return true
  end

  def qsub(pid, shell_path=Dir.pwd)
    unless pid_on_file(pid)
      add_job(pid, shell_path)
      return false
    end
    last_finished = -1
    @data.each_with_index do |job, i|
      if job[:pid] == pid
        if job[:status] == 'waiting' and i == last_finished + 1
          change_job_status(pid, 'running')
          return true
        end
        return false
      end
      last_finished = i if job[:status] == 'finished'
    end
  end

  def pid_on_file(pid)
    @data.each do |job, i|
      return job[:status] if job[:pid] == pid
    end
    return false
  end

  def qdel(pid)
    unless pid_on_file(pid)
      puts "#{pid} is not on the qeueu."
      return false
    end
    @data.each_with_index do |job, i|
      if job[:pid] == pid
        @data.delete_at(i)
        File.write(VE_TEST_FILE, YAML.dump(@data))
        puts "#{pid} is deleted from the qeueu."
        return true
      end
    end
  end

  def qstat(item_num=0)
    @data = YAML.load(File.read(VE_TEST_FILE))
    @data[item_num..-1].each do |job, i|
      puts "%5d: %10s: %s" % [job[:pid], job[:status], job[:shell_path]]
    end
  end
end

