# frozen_string_literal: true

RSpec.describe Conflow::Redis::RawValueField, redis: true do
  let(:raw_value_field) { described_class.new("test.value") }
  let(:filled_raw_value) { raw_value_field.tap { |v| v.overwrite(4.5) } }

  shared_examples "action changing raw_value" do |expected_raw_value|
    it { expect { subject }.to change { raw_value_field.to_s }.to(expected_raw_value) }
  end

  describe "#overwrite" do
    subject { filled_raw_value.overwrite(89) }
    it_behaves_like "action changing raw_value", "89"
  end

  describe "#==" do
    it { expect(filled_raw_value == 4.5).to eq false }
    it { expect(filled_raw_value == "4.5").to eq true }
    it { expect(filled_raw_value == described_class.new("test.value")).to eq true }
    it { expect(raw_value_field == described_class.new("other")).to eq true }
    it { expect(filled_raw_value == described_class.new("other")).to eq false }
    it { expect(filled_raw_value == (1..30)).to eq false }
  end

  describe "#to_s" do
    subject { filled_raw_value.to_s }
    it { is_expected.to eq "4.5" }
  end
end
