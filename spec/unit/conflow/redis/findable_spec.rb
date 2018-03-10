# frozen_string_literal: true

RSpec.describe Conflow::Redis::Findable, redis: true do
  let!(:test_class) do
    class TestClass < Conflow::Redis::Field
      include Conflow::Redis::Model
      include Conflow::Redis::Identifier
      include Conflow::Redis::Findable
    end
  end

  after { Object.send(:remove_const, "TestClass") }

  let(:instance) { test_class.new(10) }

  describe "self.included" do
    it "defines field" do
      expect(instance.type).to be_a_kind_of(Conflow::Redis::ValueField)
    end
  end

  describe "#initialize" do
    it "sets type" do
      expect(test_class.new(10).type).to eq "TestClass"
    end
  end

  describe ".find" do
    subject { test_class.find(10) }

    context "when object doesn't exist" do
      it "raises error" do
        expect { subject }.to raise_error(Redis::CommandError, "TestClass with ID 10 doesn't exist")
      end
    end

    context "when object exists" do
      before { instance }

      it { is_expected.to eq instance }
    end

    context "when object is an instance of subclass" do
      let!(:subclass) { MiniClass = Class.new(test_class) }
      after { Object.send(:remove_const, "MiniClass") }

      let!(:instance) { subclass.new(10) }

      it { is_expected.to eq instance }
      it { is_expected.to be_a_kind_of(MiniClass) }
    end
  end
end
