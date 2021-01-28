require "tiny_ge/version"
require 'yaml'
require 'thor'

#VE_SUBMIT_JOBS_FILE = File.join(ENV['HOME'],".ve_submit_jobs.txt")
VE_TEST_FILE = File.join(ENV['HOME'],".tge_test_jobs.txt")

module TGE
  class << self
    def add_job(data, pid, shell_path)
      data << {pid: pid, status: 'waiting', shell_path: shell_path, submit: Time.now, start: nil}
      File.write(VE_TEST_FILE, YAML.dump(data))
    end

    def change_job_status(data, pid, status)
      data = YAML.load(File.read(VE_TEST_FILE))
      data.each do |job, i|
        if job[:pid] == pid
          job[:status] = status
          job[:start] = Time.now if status == 'running'
          File.write(VE_TEST_FILE, YAML.dump(data))
          break
        end
      end
    end

    def qfinish(pid)
      data = YAML.load(File.read(VE_TEST_FILE))
      change_job_status(data, pid, 'finished')
    end
    def qsub(pid, shell_path=Dir.pwd)
      unless pid_on_file(pid)
        add_job(@data, pid, shell_path)
        return false
      end
      last_finished = -1
      @data.each_with_index do |job, i|
        if job[:pid] == pid
          if job[:status] == 'waiting' and i == last_finished + 1
            change_job_status(@data, pid, 'running')
            return true
          end
          return false
        end
        last_finished = i if job[:status] == 'finished'
      end
    end

    def pid_on_file(pid)
      @data = YAML.load(File.read(VE_TEST_FILE))
      if @data == false
        add_job([], pid, shell_path)
        return true
      end
      @data.each do |job, i|
        return job[:status] if job[:pid] == pid
      end
      return false
    end

    def qdel(pid)
      unless pid_on_file(pid)
        puts "#{pid} is not on the schedule."
        return false
      end
      @data.each_with_index do |job, i|
        if job[:pid] == pid
          @data.delete_at(i)
          File.write(VE_TEST_FILE, YAML.dump(@data))
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

  class MyCLI < Thor
    desc "hello NAME", "say hello to NAME"
    def hello(name)
      puts "Hello " + name
    end
  end
end
