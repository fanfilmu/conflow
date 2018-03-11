# frozen_string_literal: true

RSpec.describe Conflow::Redis::QueueJobsScript, redis: true do
  let(:flow) { Conflow::Flow.new }
  let(:job)  { Conflow::Job.new }

  let(:first_dependency)  { Conflow::Job.new }
  let(:second_dependency) { Conflow::Job.new }
  let(:other_job)         { Conflow::Job.new }

  before do
    [
      [job],
      [other_job],
      [first_dependency, [job]],
      [second_dependency, [job, other_job]]
    ].each do |(job, dependencies)|
      Conflow::Redis::AddJobScript.call(flow, job, after: dependencies || [])
    end
  end

  describe ".call" do
    subject { described_class.call(flow) }

    it "removes jobs from indegree set" do
      expect { subject }.to change { flow.indegree.to_h }.to(first_dependency.id.to_s => 1, second_dependency.id.to_s => 2)
    end

    it "moves ids to queued jobs list" do
      expect { subject }.to change { flow.queued_jobs.to_a }.to match_array [job.id.to_s, other_job.id.to_s]
    end

    it "returns ids" do
      expect(subject).to eq [job.id.to_s, other_job.id.to_s]
    end
  end
end
