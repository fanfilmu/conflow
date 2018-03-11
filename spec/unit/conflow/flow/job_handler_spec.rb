# frozen_string_literal: true

RSpec.describe Conflow::Flow::JobHandler, redis: true do
  let(:dummy)    { Class.new.tap { |klass| klass.include(described_class) } }
  let(:instance) { dummy.new }
  let(:indegree) { instance_double(Conflow::Redis::SortedSetField, delete_if: ["10"]) }

  before { allow(instance).to receive(:indegree).and_return indegree }
  before { allow(Conflow::Redis::AddJobScript).to receive(:call) }
  before { allow(instance).to receive(:queue) }
  after  { subject }

  describe "#run" do
    subject { instance.run(job_class, params: params, after: dependencies, hook: hook) }

    let(:job_class)    { instance_double(Class, name: "TestClass") }
    let(:params)       { { "test" => 14, "params" => true } }
    let(:dependencies) { instance_double(Array) }
    let(:hook)         { :a_method }

    let(:created_job) do
      satisfy do |job|
        expect(job).to be_a_kind_of(Conflow::Job)
        expect(job.class_name).to eq "TestClass"
        expect(job.params.to_h).to eq(test: 14, params: true)
        expect(job.hook).to eq :a_method
      end
    end

    shared_examples "method calling add job script and queueing jobs" do
      let(:dependency_list) { dependencies }

      it "calls add job script and enqueues new jobs" do
        expect(Conflow::Redis::AddJobScript).to receive(:call).with(instance, created_job, after: dependency_list)
        expect(instance).to receive(:queue).with(Conflow::Job.new(10))
      end
    end

    context "when dependency is a job object" do
      let(:dependencies) { Conflow::Job.new }

      it_behaves_like "method calling add job script and queueing jobs" do
        let(:dependency_list) { [dependencies] }
      end
    end

    context "when dependency is an id of a job object" do
      let(:job)          { Conflow::Job.new }
      let(:dependencies) { job.id }

      it_behaves_like "method calling add job script and queueing jobs" do
        let(:dependency_list) { [job] }
      end
    end

    context "when dependency is a class of a previously added job" do
      let(:job) { instance.run(Proc) }
      let(:dependencies) { Proc }

      it_behaves_like "method calling add job script and queueing jobs" do
        let(:dependency_list) { [job] }
      end
    end

    context "when dependency is an array of jobs" do
      let(:dependencies) { [Conflow::Job.new, Conflow::Job.new] }

      it_behaves_like "method calling add job script and queueing jobs"
    end
  end

  describe "#finish" do
    subject { instance.finish(job, :result) }

    let(:job) { instance_double(Conflow::Job, hook: :a_method) }

    it "calls complete job script and enqueues new jobs" do
      expect(Conflow::Redis::CompleteJobScript).to receive(:call).with(instance, job)
      expect(instance).to receive(:queue).with(Conflow::Job.new(10))
      expect(instance).to receive(:a_method).with(:result)
    end
  end
end
