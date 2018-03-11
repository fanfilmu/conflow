# frozen_string_literal: true

RSpec.describe Conflow::Flow, redis: true, fixtures: true do
  subject { perform_work! }

  context "for simple flow" do
    before { flow.run Operation, params: { operator: :+, number: 3 } }

    it { expect { subject }.to change { test_value }.to(3) }
  end

  shared_examples "flow changing value" do |*values| # multiple values mean "OR"
    let(:matchers) { values.map { |v| change { test_value }.to(v) } }
    let(:expectation) { matchers.inject { |result, matcher| result.or(matcher) } }

    it { expect { subject }.to expectation }
    it { expect { subject }.to change { flow.finished? }.to true }
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

  context "for flow with hooks" do
    before do
      allow($stdout).to receive(:puts)

      job = flow.run Operation, params: { operator: :+, number: 1 }
      flow.run Operation, params: { operator: :*, number: 3 }, after: job, hook: :fizz
    end

    it_behaves_like "flow changing value", 3

    it "calls hook" do
      expect($stdout).to receive(:puts).with("Fizz")
      subject
    end
  end

  context "for flow with definitions with class names" do
    before do
      flow.run Operation, params: { operator: :+, number: 400 }
      flow.run SquareRoot, after: Operation
    end

    it_behaves_like "flow changing value", 20
  end
end
