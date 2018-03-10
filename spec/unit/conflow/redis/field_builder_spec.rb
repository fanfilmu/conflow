# frozen_string_literal: true

RSpec.describe Conflow::Redis::FieldBuilder, redis: true do
  let(:test_class) { Struct.new(:key) }
  let(:instance)   { test_class.new("test_key") }

  let(:builder) { described_class.new(:params, Conflow::Redis::HashField) }

  describe "#call" do
    before { builder.call(test_class) }

    describe "getter" do
      subject { instance.params }

      it { is_expected.to be_a_kind_of(Conflow::Redis::HashField) }
      it { expect(subject.key).to eq "test_key:params" }
    end

    describe "setter" do
      subject { instance.params = { test: :param, success: true } }

      it { expect { subject }.to change { instance.params.to_h }.to("test" => "param", "success" => true) }
    end
  end
end
