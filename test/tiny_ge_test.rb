require "test_helper"
require 'command_line/global'

#VE_TEST_FILE = File.join(ENV['HOME'],".tge_test_jobs.txt")

class TGETest < Minitest::Test
  def setup
    @pid = $$
    @tge = TGE.new
  end
  def test_it_has_a_version_number
    refute_nil TGE::VERSION
  end

  def test_it_has_the_jobs_file
    assert File.exist?(VE_TEST_FILE)
  end

  def test_qsub_job
    @tge.qsub(@pid)
    assert @tge.pid_on_file(@pid)
    @tge.qdel(@pid)
  end

  def test_qsub_running
    @tge.qsub(14709)
    assert_equal @tge.pid_on_file(14709), 'running'
  end

  def test_qdel
    @tge.qsub(@pid)
    @tge.qdel(@pid)
    assert !@tge.pid_on_file(@pid)
  end

  def test_q_finish
    @tge.qfinish(9256)
  end

  def test_read_qstat
    @tge.qstat(0)
  end
end
