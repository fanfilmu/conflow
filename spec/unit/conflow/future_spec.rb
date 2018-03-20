# frozen_string_literal: true

RSpec.describe Conflow::Future, redis: true do
  let(:source_job)    { Conflow::Job.new }
  let(:depending_job) { Conflow::Job.new }

  let(:base_future) { described_class.new(source_job) }

  describe "[]" do
    context "when nested once" do
      subject { base_future[:email] }

      it { is_expected.to have_attributes(job: source_job, result_key: :email) }
    end

    context "when nested twice" do
      subject { base_future[:user][:email] }

      it { expect { subject }.to raise_error(Conflow::InvalidNestedFuture, "Futures don't allow extracting nested fields") }
    end
  end

  describe "#build_promise" do
    let(:future) { base_future[:email] }

    subject { future.build_promise(depending_job, :destination) }

    it { expect(subject.job_id.to_s).to eq source_job.id.to_s }
    it { expect(subject.hash_field.to_s).to eq "destination" }
    it { expect(subject.result_key.to_s).to eq "email" }

    it { expect { subject }.to change { depending_job.promise_ids.to_a }.to ["1"] }
  end
end
