require "tiny_ge/version"
require 'yaml'
require 'thor'
require 'command_line/global'

#VE_SUBMIT_JOBS_FILE = File.join(ENV['HOME'],".ve_submit_jobs.txt")
VE_TEST_FILE = File.join(ENV['HOME'],".tge_test_jobs.txt")

class TGE
  def initialize(q_file=VE_TEST_FILE)
    p q_file
    command_line("touch #{q_file}") unless File.exist?(q_file)
    @q_file = VE_TEST_FILE
    @data = YAML.load(File.read(@q_file))
  end

  def add_job(pid, shell_path)
    shell_file = "./test.s#{pid}"
    shell_script = mk_shell_script(pid, shell_path)
    File.write(shell_file, shell_script)

    p pid0 = spawn("sh #{shell_file}", :out => "test.o#{pid}", :err => "test.e#{pid}")
    Process.detach(pid0)
    puts "#{pid} is added on the queue."

    @data << {pid: pid, status: 'waiting', shell_path: shell_path,
      real_pid: pid0,
      submit: Time.now,
      start: nil,
      finish: nil
    }
    File.write(VE_TEST_FILE, YAML.dump(@data))
  end

  def change_job_status(pid, status)
    @data.each do |job, i|
      if job[:pid] == pid
        job[:status] = status
        case status
        when 'running' ;  job[:start] = Time.now
        when 'finished';  job[:finish] = Time.now
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
        if job[:status] == 'running'
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
        res = command_line("kill -9 #{job[:real_pid]}")
        p res
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

