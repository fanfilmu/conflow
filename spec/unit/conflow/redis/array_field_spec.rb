# frozen_string_literal: true

RSpec.describe Conflow::Redis::ArrayField, redis: true do
  let(:array_field)  { described_class.new("test.array") }
  let(:filled_array) { array_field.tap { |ary| %w[a b c].each { |v| ary << v } } }

  shared_examples "action changing array" do |expected_array|
    it { expect { subject }.to change { array_field.to_a }.to(expected_array) }
  end

  describe "#[]" do
    subject { array_field[0] }

    it { is_expected.to eq nil }

    context "when array is not empty" do
      before { array_field << "val" }
      it { is_expected.to eq "val" }
    end
  end

  describe "#[]=" do
    subject { filled_array[1] = "oy" }
    it_behaves_like "action changing array", %w[a oy c]
  end

  describe "#insert" do
    context "when used with before" do
      subject { filled_array.insert("something", before: :c) }
      it_behaves_like "action changing array", %w[a b something c]
    end

    context "when used with after" do
      subject { filled_array.insert("something", after: :a) }
      it_behaves_like "action changing array", %w[a something b c]
    end

    context "when used without any option" do
      subject { filled_array.insert("something") }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end

  describe "#size" do
    subject { filled_array.size }
    it { is_expected.to eq 3 }
  end

  describe "#to_a" do
    subject { filled_array.to_a }
    it { is_expected.to eq %w[a b c] }
  end

  describe "#pop" do
    subject { filled_array.pop }
    it_behaves_like "action changing array", %w[a b]
    it { is_expected.to eq "c" }
  end

  describe "#push" do
    subject { filled_array.push("d", "e") }
    it_behaves_like "action changing array", %w[a b c d e]
  end

  describe "#concat" do
    subject { filled_array.concat %w[d e] }
    it_behaves_like "action changing array", %w[a b c d e]
  end

  describe "#shift" do
    subject { filled_array.shift }
    it_behaves_like "action changing array", %w[b c]
    it { is_expected.to eq "a" }
  end

  describe "#unshift" do
    subject { filled_array.unshift("d") }
    it_behaves_like "action changing array", %w[d a b c]
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
