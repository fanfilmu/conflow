# frozen_string_literal: true

RSpec.describe Conflow do
  it "has a version number" do
    expect(Conflow::VERSION).not_to be nil
  end

  describe ".redis=" do
    before { Conflow.redis = redis }

    context "when assigned regular connection" do
      let(:redis) { Redis.new }

      it "wraps connection" do
        expect(Conflow.redis).to be_a_kind_of(Conflow::Redis::ConnectionWrapper)
      end
    end

    context "when assigned connection pool" do
      let(:redis) { ConnectionPool.new { Redis.new } }

      it "wraps connection" do
        expect(Conflow.redis).to eq redis
      end
    end
  end
end
