# frozen_string_literal: true

RSpec.describe Conflow::Redis::ValueField, redis: true do
  let(:value_field) { described_class.new("test.value") }
  let(:filled_value) { value_field.tap { |v| v.overwrite(4.5) } }

  shared_examples "action changing value" do |expected_value|
    it { expect { subject }.to change { value_field.value }.to(expected_value) }
  end

  describe "#overwrite" do
    subject { filled_value.overwrite("NaN") }
    it_behaves_like "action changing value", "NaN"
  end

  describe "#default" do
    context "when value is empty" do
      subject { value_field.default(10) }
      it_behaves_like "action changing value", 10
    end

    context "when value is not empty" do
      subject { filled_value.default(10) }
      it { expect { subject }.to_not(change { filled_value.value }) }
    end
  end

  describe "#==" do
    it { expect(filled_value == 4.5).to eq true }
    it { expect(filled_value == described_class.new("test.value")).to eq true }
    it { expect(value_field == described_class.new("other")).to eq true }
    it { expect(filled_value == described_class.new("other")).to eq false }
    it { expect(filled_value == (1..30)).to eq false }
  end

  describe "#to_s" do
    subject { filled_value.to_s }
    it { is_expected.to eq "4.5" }
  end
end
