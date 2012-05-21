require 'spec_helper'

  class SerialJob
    extend Resque::Plugins::LonelyJob
    @queue = :serial_work

    def self.perform(*args); end
  end

describe Resque::Plugins::LonelyJob do
  describe ".can_lock_queue?" do
    before do
      SerialJob.unlock_queue(:serial_work)
    end

    it 'can lock a queue' do
      SerialJob.can_lock_queue?(:serial_work).should be_true
    end

    it 'cannot lock an already locked queue' do
      SerialJob.can_lock_queue?(:serial_work).should be_true
      SerialJob.can_lock_queue?(:serial_work).should be_false
    end
  end

  describe ".perform" do
    it 'should lock and unlock the queue' do
      job = Resque::Job.new(:serial_work, { 'class' => 'SerialJob', 'args' => %w[account_one job_one] })

      # job is the first SerialJob to run so it can lock the queue and perform
      SerialJob.should_receive(:can_lock_queue?).and_return(true)

      # but it should also clean up after itself
      SerialJob.should_receive(:unlock_queue)

      job.perform
    end

    it 'should clean up lock even with catastrophic job failure' do
      job = Resque::Job.new(:serial_work, { 'class' => 'SerialJob', 'args' => %w[account_one job_one] })

      # job is the first SerialJob to run so it can lock the queue and perform
      SerialJob.should_receive(:can_lock_queue?).and_return(true)

      # but we have a catastrophic job failure
      SerialJob.should_receive(:perform).and_raise(Exception)

      # and still it should clean up after itself
      SerialJob.should_receive(:unlock_queue)

      # unfortunately, the job will be lost but resque doesn't guarantee jobs
      # aren't lost
      -> { job.perform }.should raise_error(Exception)
    end

    it 'should place self at the end of the queue if unable to acquire the lock' do
      Resque.size(:serial_work).should == 0

      job = Resque::Job.new(:serial_work, { 'class' => 'SerialJob', 'args' => %w[account_one job_one] })

      SerialJob.should_receive(:can_lock_queue?).and_return(false)

      # perform returns false when DontPerform exception is raised in
      # before_perform callback
      job.perform.should be_false

      Resque.size(:serial_work).should == 1
    end
  end
end
