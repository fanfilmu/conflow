# frozen_string_literal: true

RSpec.describe Conflow::Worker, redis: true do
  let(:flow) { Conflow::Flow.new }
  let(:job)  { flow.run(Proc, params: { something: "cool" }) }

  before { allow(flow).to receive(:queue) }

  let(:dummy)    { Class.new.tap { |klass| klass.include(described_class) } }
  let(:instance) { dummy.new }

  describe "#perform" do
    it { expect { |b| instance.perform(flow.id, job.id, &b) }.to yield_with_args(Proc, something: "cool") }
  end
end
