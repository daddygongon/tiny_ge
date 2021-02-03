require "tiny_ge/version"
require "tiny_ge/child_process"
require 'yaml'
require 'thor'
require 'command_line/global'

#VE_SUBMIT_JOBS_FILE = File.join(ENV['HOME'],".ve_submit_jobs.txt")
VE_TEST_FILE = File.join(ENV['HOME'],".tge_test_jobs.txt")

class TGE
  include ChildProcess
  def initialize(line=0)
    @q_file =VE_TEST_FILE
    command_line("touch #{@q_file}") unless File.exist?(@q_file)
    @data = YAML.load(File.read(@q_file))
    unless @data
      @data = []
      puts 'no data'
      return
    end
  end

  def change_job_status(pid, status)
    @data.each do |job, i|
      if job[:pid] == pid
        job[:status] = status
        case status
        when 'running' ;  job[:start] = Time.now
        when 'finished';  job[:finish] = Time.now
        when 'deleted' ;  job[:finish] = Time.now
        end
        File.write(VE_TEST_FILE, YAML.dump(@data))
        break
      end
    end
  end

  def qfinish(pid)
    change_job_status(pid, 'finished')
    return true
  end

  def add_job(pid, shell_path)
    shell_name = File.basename(shell_path,'.sh')
    shell_file = "./#{shell_name}.s#{pid}"
    shell_script = mk_shell_script(pid, shell_path)
    File.write(shell_file, shell_script)

    p pid0 = spawn("sh #{shell_file}",
                   :out => "#{shell_name}.o#{pid}",
                   :err => "#{shell_name}.e#{pid}")
    Process.detach(pid0)
    puts "#{pid} is added on the queue."

    @data << {pid: pid, status: 'waiting',
      shell_path: shell_path,
      real_pid: pid0,
      submit: Time.now,
      start: nil,
      finish: nil
    }
    File.write(VE_TEST_FILE, YAML.dump(@data))
  end

  def qsub(pid, shell_path=Dir.pwd)
    unless pid_on_file(pid)
      add_job(@data.size, shell_path)
      return false
    end

    @data.each do |job|
      if job[:pid] == pid and job[:status] == 'waiting'
        change_job_status(pid, 'running')
        return true
      end
      return false if job[:status] == 'waiting' or job[:status] == 'running'
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
        kill_all_child_process(job[:real_pid])
        res = command_line("kill -9 #{job[:real_pid]}")
        p res
        # @data.delete_at(i)
        change_job_status(pid, 'deleted')
        File.write(VE_TEST_FILE, YAML.dump(@data))
        puts "#{pid} is deleted from the qeueu."

        return true
      end
    end
  end

  def qstat(item_num=0)
    @data[item_num..-1].each do |job, i|
      real_pid = job[:real_pid] || 0
      puts "%5d: %5d: %10s: %s" % [job[:pid], real_pid, job[:status], job[:shell_path]]
    end
  end

  def mk_shell_script(pid, shell_path)
    return <<~EOS
    #!/bin/sh
    while ! qsub #{pid}; do
      sleep 10
      done

      sh #{shell_path}

      qfinish #{pid}
      EOS
    end

  end

