# frozen_string_literal: true

RSpec.describe Conflow::Redis::HashField, redis: true do
  let(:hash_field) { described_class.new("test.hash") }
  let(:filled_hash) { hash_field.tap { |h| h.merge(a: 1, b: 2, c: 4) } }

  shared_examples "action changing hash" do |expected_hash|
    it { expect { subject }.to change { hash_field.to_h }.to(expected_hash) }
  end

  describe "#[]" do
    subject { hash_field["key"] }

    it { is_expected.to eq nil }

    context "when field is set" do
      before { hash_field["key"] = "val" }
      it { is_expected.to eq "val" }
    end
  end

  describe "#[]=" do
    subject { hash_field["key"] = "something" }
    it_behaves_like "action changing hash", "key" => "something"
  end

  describe "#merge" do
    subject { filled_hash.merge(c: 8, d: 4) }
    it_behaves_like "action changing hash", "a" => 1, "b" => 2, "c" => 8, "d" => 4
  end

  describe "#delete" do
    subject { filled_hash.delete(:a, :b) }
    it_behaves_like "action changing hash", "c" => 4
  end

  describe "#overwrite" do
    subject { filled_hash.overwrite("diff" => "y") }
    it_behaves_like "action changing hash", "diff" => "y"
  end

  describe "#keys" do
    subject { filled_hash.keys }
    it { is_expected.to eq %w[a b c] }
  end

  describe "#size" do
    subject { filled_hash.size }
    it { is_expected.to eq 3 }
  end

  describe "#each" do
    subject { filled_hash.each.to_a }
    it { is_expected.to eq [["a", 1], ["b", 2], ["c", 4]] }
  end

  describe "#==" do
    it { expect(filled_hash == { "a" => 1, "b" => 2, "c" => 4 }).to eq true }
    it { expect(filled_hash == described_class.new("test.hash")).to eq true }
    it { expect(hash_field == described_class.new("other")).to eq true }
    it { expect(filled_hash == described_class.new("other")).to eq false }
    it { expect(filled_hash == 5).to eq false }
  end

  describe "#to_s" do
    subject { filled_hash.to_s }
    it { is_expected.to eq %({"a"=>1, "b"=>2, "c"=>4}) }
  end
end
