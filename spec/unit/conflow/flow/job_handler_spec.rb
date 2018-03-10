# frozen_string_literal: true

RSpec.describe Conflow::Flow::JobHandler, redis: true do
  let(:dummy)    { Class.new.tap { |klass| klass.include(described_class) } }
  let(:instance) { dummy.new }
  let(:indegree) { instance_double(Conflow::Redis::SortedSetField, delete_if: ["10"]) }

  before { allow(instance).to receive(:indegree).and_return indegree }
  after  { subject }

  describe "#run" do
    subject { instance.run(job_class, params: params, after: dependencies) }

    let(:job_class)    { instance_double(Class, name: "TestClass") }
    let(:params)       { { "test" => 14, "params" => true } }
    let(:dependencies) { instance_double(Array) }

    let(:created_job) do
      satisfy do |job|
        expect(job).to be_a_kind_of(Conflow::Job)
        expect(job.class_name).to eq "TestClass"
        expect(job.params.to_h).to eq(test: 14, params: true)
      end
    end

    it "calls add job script and enqueues new jobs" do
      expect(Conflow::Redis::AddJobScript).to receive(:call).with(instance, created_job, after: dependencies)
      expect(instance).to receive(:queue).with(Conflow::Job.new(10))
    end
  end

  describe "#finish" do
    subject { instance.finish(job) }

    let(:job) { instance_double(Conflow::Job) }

    it "calls complete job script and enqueues new jobs" do
      expect(Conflow::Redis::CompleteJobScript).to receive(:call).with(instance, job)
      expect(instance).to receive(:queue).with(Conflow::Job.new(10))
    end
  end
end
