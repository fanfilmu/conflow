# frozen_string_literal: true

RSpec.describe Conflow::Redis::AddJobScript, redis: true do
  let(:flow) { Conflow::Flow.new }
  let(:job)  { Conflow::Job.new }

  before { described_class.call(flow, previous_job) if defined?(previous_job) }

  describe ".call" do
    before { described_class.call(flow, job, after: dependencies) }
    let(:dependencies) { [] }

    context "when there are no dependencies" do
      it "adds job to the list" do
        expect(flow.jobs.map(&:id)).to eq [job.id]
      end

      it "adds job to indegree set with score 0" do
        expect(flow.indegree.to_h).to eq "1" => 0
      end
    end

    shared_examples "method adding job" do
      it "adds job to the list" do
        expect(flow.jobs.map(&:id)).to eq [job.id, previous_job.id]
      end

      it "adds job to indegree set with score 1" do
        expect(flow.indegree.to_h).to eq job.id.to_s => 1, previous_job.id.to_s => 0
      end

      it "adds job as successor" do
        expect(previous_job.successors).to eq [job]
      end
    end

    context "with one dependency" do
      context "passed as list of values" do
        let(:previous_job) { Conflow::Job.new }
        let(:dependencies) { [previous_job.id] }

        it_behaves_like "method adding job"
      end

      context "passed as object" do
        let(:previous_job) { Conflow::Job.new }
        let(:dependencies) { previous_job }

        it_behaves_like "method adding job"
      end
    end

    context "with multiple dependencies" do
      let(:previous_job)  { Conflow::Job.new }
      let(:completed_job) { Conflow::Job.new.tap { |j| j.status = 1 } }
      let(:dependencies)  { [previous_job.id, completed_job] }

      it_behaves_like "method adding job"
    end
  end
end
