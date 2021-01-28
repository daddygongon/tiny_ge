require "test_helper"
require 'command_line/global'

#VE_TEST_FILE = File.join(ENV['HOME'],".tge_test_jobs.txt")

class TGETest < Minitest::Test
  def setup
    command_line "touch #{VE_TEST_FILE}"
    @pid = $$
  end
  def test_it_has_a_version_number
    refute_nil TGE::VERSION
  end

  def test_it_has_the_jobs_file
    assert File.exist?(VE_TEST_FILE)
  end

  def test_qsub_job
    TGE::qsub(@pid)
    assert TGE.pid_on_file(@pid)
    TGE::qdel(@pid)
  end

  def test_qsub_running
    TGE::qsub(14709)
    assert_equal TGE.pid_on_file(14709), 'running'
  end

  def test_qdel
    TGE::qsub(@pid)
    TGE::qdel(@pid)
    assert !TGE.pid_on_file(@pid)
  end

  def test_q_finish
    TGE::qfinish(9256)
  end

  def test_read_qstat
    TGE::qstat(0)
  end
end
