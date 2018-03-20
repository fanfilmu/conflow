# frozen_string_literal: true

RSpec.describe Conflow::Redis::ResolvePromisesScript, redis: true do
  def job_with_result(result = {})
    Conflow::Job.new.tap { |job| job.result = result }
  end

  let!(:first_dependency)  { job_with_result(first: "success",  type: :hard_work) }
  let!(:second_dependency) { job_with_result(second: "pending", type: :easy) }

  let!(:other_job) { job_with_result(other: "unrelated", type: :dontcare) }

  let!(:first_promise)  { Conflow::Future.new(first_dependency,  :type).build_promise(job, :work_type) }
  let!(:second_promise) { Conflow::Future.new(second_dependency, :second).build_promise(job, :status) }

  let!(:other_promise) { Conflow::Future.new(other_job, :type).build_promise(second_dependency, :status) }

  let!(:job) { Conflow::Job.new.tap { |job| job.params = { old: 30 } } }

  describe ".call" do
    subject { described_class.call(nil, job) }

    it "copies parameters from dependencies" do
      expect { subject }.to change { job.params.to_h }.from(old: 30).to(old: 30, work_type: "hard_work", status: "pending")
    end

    it "doesn't change parameters of other jobs" do
      expect { subject }.to_not(change { other_job.params.to_h })
    end
  end
end
