# frozen_string_literal: true

RSpec.describe Conflow::Promise, redis: true do
  let(:promise) { described_class.new }

  subject { promise }

  it { is_expected.to be_a_kind_of(Conflow::Redis::Model) }
  it { is_expected.to be_a_kind_of(Conflow::Redis::Identifier) }

  context "fields" do
    it { expect(subject.job_id).to be_a_kind_of(Conflow::Redis::RawValueField) }
    it { expect(subject.result_key).to be_a_kind_of(Conflow::Redis::RawValueField) }
    it { expect(subject.hash_field).to be_a_kind_of(Conflow::Redis::RawValueField) }
  end
end
