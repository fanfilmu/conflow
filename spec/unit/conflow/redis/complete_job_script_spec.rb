# frozen_string_literal: true

RSpec.describe Conflow::Redis::CompleteJobScript, redis: true do
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
    subject { described_class.call(flow, job) }

    it "changes job status" do
      expect { subject }.to change { job.status.to_s }.from("0").to("1")
    end

    it "changes indegree of first dependency" do
      expect { subject }.to change { flow.indegree[first_dependency.id] }.from(1).to(0)
    end

    it "changes indegree of second dependency" do
      expect { subject }.to change { flow.indegree[second_dependency.id] }.from(2).to(1)
    end

    it "doesn't change indegree of other job" do
      expect { subject }.to_not(change { flow.indegree[other_job.id] })
    end
  end
end
