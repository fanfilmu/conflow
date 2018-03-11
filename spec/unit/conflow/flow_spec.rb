# frozen_string_literal: true

RSpec.describe Conflow::Flow, redis: true do
  subject { described_class.new }

  before { subject.job_ids << 5 }

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
    let(:flow) { instance_double(described_class) }

    before { allow(described_class).to receive(:new).and_return(flow) }
    after  { described_class.create("An arg") }

    it "creates and configures job" do
      expect(flow).to receive(:configure).with("An arg")
    end
  end
end
