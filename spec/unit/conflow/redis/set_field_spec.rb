# frozen_string_literal: true

RSpec.describe Conflow::Redis::SetField, redis: true do
  let(:set_field)  { described_class.new("test.sset") }
  let(:filled_set) { set_field.tap { |field| field.add("best", "tie", "last") } }

  shared_examples "action changing set" do |expected_set|
    it { expect { subject }.to change { set_field.to_a }.to match_array(expected_set) }
  end

  describe "#add" do
    subject { filled_set.add(:tie, :other) }
    it_behaves_like "action changing set", %w[best tie last other]
  end

  describe "#size" do
    subject { filled_set.size }
    it { is_expected.to eq 3 }
  end

  describe "#to_a" do
    subject { filled_set.to_a }
    it { is_expected.to match_array %w[best tie last] }
  end

  describe "#overwrite" do
    subject { filled_set.overwrite(%i[super new]) }
    it_behaves_like "action changing set", %w[super new]
  end
end
