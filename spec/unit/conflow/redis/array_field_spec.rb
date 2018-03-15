# frozen_string_literal: true

RSpec.describe Conflow::Redis::ArrayField, redis: true do
  let(:array_field)  { described_class.new("test.array") }
  let(:filled_array) { array_field.tap { |ary| %w[a b c].each { |v| ary << v } } }

  shared_examples "action changing array" do |expected_array|
    it { expect { subject }.to change { array_field.to_a }.to(expected_array) }
  end

  describe "#size" do
    subject { filled_array.size }
    it { is_expected.to eq 3 }
  end

  describe "#to_a" do
    subject { filled_array.to_a }
    it { is_expected.to eq %w[a b c] }
  end

  describe "#push" do
    subject { filled_array.push("d", "e") }
    it_behaves_like "action changing array", %w[a b c d e]
  end

  describe "#overwrite" do
    subject { filled_array.overwrite %w[better things] }
    it_behaves_like "action changing array", %w[better things]
  end

  describe "#each" do
    subject { filled_array.each.to_a }
    it { is_expected.to eq %w[a b c] }
  end

  describe "#==" do
    it { expect(filled_array == %w[a b c]).to eq true }
    it { expect(filled_array == described_class.new("test.array")).to eq true }
    it { expect(array_field == described_class.new("other")).to eq true }
    it { expect(filled_array == described_class.new("other")).to eq false }
    it { expect(filled_array == 5).to eq false }
  end

  describe "#to_s" do
    subject { filled_array.to_s }
    it { is_expected.to eq %(["a", "b", "c"]) }
  end
end
