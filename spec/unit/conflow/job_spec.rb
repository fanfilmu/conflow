# frozen_string_literal: true

RSpec.describe Conflow::Job, redis: true do
  let(:job) { described_class.new }

  subject { job }

  before { job.successor_ids << 15 }

  it { is_expected.to be_a_kind_of(Conflow::Redis::Model) }
  it { is_expected.to be_a_kind_of(Conflow::Redis::Identifier) }

  context "fields" do
    it { expect(subject.successors).to eq [Conflow::Job.new(15)] }
    it { expect(subject.successor_ids).to eq ["15"] }
    it { expect(subject.status).to eq "0" }
  end

  describe "#worker_type" do
    before { job.class_name = "Conflow::Redis::Script" }

    subject { job.worker_type }

    it { is_expected.to eq Conflow::Redis::Script }
  end
end
