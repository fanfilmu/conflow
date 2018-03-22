# frozen_string_literal: true

RSpec.describe Conflow::Flow, redis: true do
  let(:flow) { described_class.new }
  before { flow.job_ids << 5 }

  subject { flow }

  it { is_expected.to be_a_kind_of(Conflow::Redis::Model) }
  it { is_expected.to be_a_kind_of(Conflow::Redis::Identifier) }
  it { is_expected.to be_a_kind_of(Conflow::Redis::Findable) }
  it { is_expected.to be_a_kind_of(Conflow::Flow::JobHandler) }

  context "fields" do
    it { expect(subject.jobs).to eq [Conflow::Job.new(5)] }
    it { expect(subject.job_ids).to eq ["5"] }
    it { expect(subject.indegree).to be_a_kind_of(Conflow::Redis::SortedSetField) }
  end

  describe ".create" do
    let(:mock_flow) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(mock_flow)
      allow(mock_flow).to receive(:with_lock) { |&block| block.call }
    end

    after { described_class.create("An arg") }

    it "creates and configures job" do
      expect(mock_flow).to receive(:configure).with("An arg")
    end
  end

  describe "#finished?" do
    let(:flow) { described_class.new }
    subject { flow.finished? }

    context "when there are no pending jobs" do
      it { is_expected.to eq true }

      context "but flow is locked" do
        before { flow.lock = 1 }

        it { is_expected.to eq false }
      end
    end

    context "when there are jobs in indegree set" do
      before { flow.indegree.add(5 => 0) }
      it { is_expected.to eq false }
    end

    context "when there are jobs in queued jobs set" do
      before { flow.queued_jobs.add(5) }
      it { is_expected.to eq false }
    end
  end

  describe "#with_lock" do
    let(:flow) { described_class.new }

    it "sets a lock inside the block" do
      expect(flow.lock.value).to_not eq 1

      flow.with_lock do
        expect(flow.lock.value).to eq 1
      end

      expect(flow.lock.value).to_not eq 1
    end

    context "after lifting the lock" do
      after { flow.with_lock {} }

      it "enqueues jobs" do
        expect(flow).to receive(:queue_available_jobs)
      end
    end
  end
end
