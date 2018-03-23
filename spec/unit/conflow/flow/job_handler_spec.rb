# frozen_string_literal: true

RSpec.describe Conflow::Flow::JobHandler, redis: true do
  let(:dummy)      { Class.new.tap { |klass| klass.include(described_class) } }
  let(:instance)   { dummy.new }
  let(:indegree)   { instance_double(Conflow::Redis::SortedSetField) }
  let(:finished)   { false }
  let(:lock_value) { 0 }

  before do
    allow(instance).to receive(:indegree).and_return indegree
    allow(instance).to receive(:queue)
    allow(instance).to receive(:finished?).and_return(finished)
    allow(instance).to receive(:a_method).and_return(:result)
    allow(instance).to receive(:lock).and_return(double(value: lock_value))

    allow(Conflow::Redis::AddJobScript).to receive(:call)
    allow(Conflow::Redis::QueueJobsScript).to receive(:call).and_return(["10"])
    allow(Conflow::Redis::CompleteJobScript).to receive(:call)
  end

  after { subject }

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

    context "when dependency is a class which was not enqueued" do
      let(:dependencies) { Proc }

      it_behaves_like "method calling add job script and queueing jobs" do
        let(:dependency_list) { [] }
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

    context "when locked" do
      let(:lock_value) { 1 }

      it "doesn't enqueue jobs" do
        expect(instance).to_not receive(:queue)
      end
    end
  end

  describe "#finish" do
    subject { instance.finish(job, result) }

    let(:job)    { instance_double(Conflow::Job, :result= => true) }
    let(:result) { { result: 114 } }

    it "calls complete job script and enqueues new jobs" do
      expect(Conflow::Redis::CompleteJobScript).to receive(:call).with(instance, job)
      expect(instance).to receive(:queue).with(Conflow::Job.new(10))
      expect(job).to receive(:result=).with(result: 114)
    end

    context "when flow is not finished" do
      it "doesn't remove flow" do
        expect(instance).to_not receive(:destroy!)
      end
    end

    context "when flow is finished" do
      let(:finished) { true }

      it "removes flow" do
        expect(instance).to receive(:destroy!)
      end
    end

    context "when result is not a hash" do
      let(:result) { true }

      it "doesn't assign it" do
        expect(job).to_not receive(:result=)
      end
    end
  end
end
