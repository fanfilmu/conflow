# frozen_string_literal: true

RSpec.describe Conflow::Flow, redis: true, fixtures: true do
  subject { perform_work! }

  let(:initial_value) { 0 }

  context "for simple flow" do
    before { flow.run Operation, params: { operator: :+, number: 3 } }

    it { expect { subject }.to change { test_value }.to(3) }
  end

  shared_examples "flow changing value" do |*values| # multiple values mean "OR"
    before { allow(Conflow::Promise).to receive(:new).and_call_original }

    let(:matchers) { values.map { |v| change { test_value }.to(v) } }
    let(:expectation) { matchers.inject { |result, matcher| result.or(matcher) } }

    it { expect { subject }.to expectation }
    it { expect { subject }.to change { flow.finished? }.to true }

    let(:expected_keys) { ["test_key", Conflow::Flow.counter_key, Conflow::Job.counter_key] }

    it { expect { subject }.to change { redis.keys("*") }.to include(*expected_keys) }
  end

  context "for flow with multiple independent jobs" do
    before do
      flow.run Operation, params: { operator: :+, number: 3 }
      flow.run Operation, params: { operator: :*, number: 2 }
    end

    it_behaves_like "flow changing value", 6, 3
  end

  context "for flow with multiple dependent jobs" do
    before do # (3 - 10) * 9 / 3 - (-10)
      a1 = flow.run Operation, params: { operator: :+, number: 3 }
      a2 = flow.run Operation, params: { operator: :-, number: 18 }

      m1 = flow.run Operation, params: { operator: :*, number: 9 }, after: [a1, a2]
      m2 = flow.run Operation, params: { operator: :/, number: 3 }, after: [a1, a2]

      flow.run Operation, params: { operator: :-, number: -10 }, after: [m1, m2]
    end

    it_behaves_like "flow changing value", -35
  end

  context "for flow with promises" do
    context "simple usage" do
      before do
        job = flow.run Operation, params: { operator: :+, number: 5 }
        flow.run Operation, params: { operator: :*, number: job.outcome[:value] }
      end

      it_behaves_like "flow changing value", 25
    end

    context "when same promise is used multiple times" do
      let(:initial_value) { 4 }
      before do
        job = flow.run Operation, params: { operator: :-, number: 2 }
        value = job.outcome[:value]
        flow.run Operation, params: { operator: :*, number: value }
        flow.run Operation, params: { operator: :*, number: value }
      end

      it_behaves_like "flow changing value", 8
    end
  end

  context "for flow with definitions with class names" do
    before do
      flow.run Operation, params: { operator: :+, number: 400 }
      flow.run SquareRoot, after: Operation
    end

    it_behaves_like "flow changing value", 20
  end

  context "for flow with dependency on job that was never enqueued" do
    let(:initial_value) { 4 }

    before { flow.run SquareRoot, after: Operation }

    it_behaves_like "flow changing value", 2
  end
end
