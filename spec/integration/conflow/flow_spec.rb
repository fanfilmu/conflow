# frozen_string_literal: true

RSpec.describe Conflow::Flow, redis: true, fixtures: true do
  subject { perform_work! }

  context "for simple flow" do
    before { flow.run Operation, params: { operator: :+, number: 3 } }

    it { expect { subject }.to change { test_value }.to(3) }
  end

  context "for flow with multiple independent jobs" do
    before do
      flow.run Operation, params: { operator: :+, number: 3 }
      flow.run Operation, params: { operator: :*, number: 2 }
    end

    it { expect { subject }.to change { test_value }.to(6).or(change { test_value }.to(3)) }
  end

  context "for flow with multiple dependent jobs" do
    before do # (3 - 10) * 9 / 3 - (-10)
      a1 = flow.run Operation, params: { operator: :+, number: 3 }
      a2 = flow.run Operation, params: { operator: :-, number: 18 }

      m1 = flow.run Operation, params: { operator: :*, number: 9 }, after: [a1, a2]
      m2 = flow.run Operation, params: { operator: :/, number: 3 }, after: [a1, a2]

      flow.run Operation, params: { operator: :-, number: -10 }, after: [m1, m2]
    end

    it { expect { subject }.to change { test_value }.to(-35) }
  end
end
