# frozen_string_literal: true

RSpec.describe Conflow::Redis::Script, redis: true do
  let(:test_class) do
    Class.new(described_class) do
      self.script = <<~LUA.chop
        return {KEYS[1], ARGV[1] / 2}
      LUA
    end
  end

  before  { redis.script(:flush) }
  subject { test_class.call(["a"], [4]) }

  describe ".call" do
    it { is_expected.to eq ["a", 2] }
  end

  describe ".cache_scripts=" do
    after { subject }

    context "when scripts are cached" do
      it "uses cached version" do
        expect(redis).to receive(:evalsha)
          .with("939711ba3f4be5667880d1b03e02b63a0b6c30f0", ["a"], [4])
          .twice
          .and_call_original
      end

      it "loads script to Redis" do
        expect(redis).to receive(:script)
          .with(:load, test_class.script)
          .and_call_original
      end
    end

    context "when scripts are not cached" do
      before { described_class.cache_scripts = false }

      it "sends whole script" do
        expect(redis).to receive(:eval).with("return {KEYS[1], ARGV[1] / 2}", ["a"], [4]).and_call_original
      end
    end
  end
end
