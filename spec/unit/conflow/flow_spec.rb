# frozen_string_literal: true

RSpec.describe Conflow::Flow, redis: true do
  subject { described_class.new }

  before { subject.job_ids << 5 }

  it { is_expected.to be_a_kind_of(Conflow::Redis::Model) }
  it { is_expected.to be_a_kind_of(Conflow::Redis::Identifier) }

  context "fields" do
    it { expect(subject.jobs).to eq [Conflow::Job.new(5)] }
    it { expect(subject.job_ids).to eq ["5"] }
    it { expect(subject.indegree).to be_a_kind_of(Conflow::Redis::SortedSetField) }
  end
end
