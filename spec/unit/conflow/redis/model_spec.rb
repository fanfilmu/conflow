# frozen_string_literal: true

RSpec.describe Conflow::Redis::Model, redis: true do
  let(:test_class) do
    Class.new(Conflow::Redis::Field) do
      include Conflow::Redis::Model

      field :params,  :hash
      field :records, :array
      field :status,  :value
      field :zset,    :sorted_set
      field :sset,    :set
    end
  end

  let(:related_model) do
    Class.new(Conflow::Redis::Field) do
      include Conflow::Redis::Model
      alias_method :id, :key
      field :name, :value
    end
  end

  let(:model_with_relation) do
    m = related_model

    Class.new(Conflow::Redis::Field) do
      include Conflow::Redis::Model
      alias_method :id, :key
      has_many :workers, m
      field :status, :value
    end
  end

  let(:instance) { test_class.new("test_key") }

  it "defines proper methods" do
    expect(instance).to respond_to(:params, :params=, :records, :records=, :status, :status=, :zset, :zset=, :sset, :sset=)
  end

  it "defines proper getters" do
    expect(instance.params).to  be_a_kind_of(Conflow::Redis::HashField)
    expect(instance.records).to be_a_kind_of(Conflow::Redis::ArrayField)
    expect(instance.status).to  be_a_kind_of(Conflow::Redis::ValueField)
    expect(instance.zset).to    be_a_kind_of(Conflow::Redis::SortedSetField)
    expect(instance.sset).to    be_a_kind_of(Conflow::Redis::SetField)
  end

  describe "#==" do
    subject { instance == other }

    context "when other is a model with same key" do
      let(:other) { test_class.new("test_key") }

      it { is_expected.to eq true }
    end

    context "when other is a model with different key" do
      let(:other) { test_class.new("other_key") }

      it { is_expected.to eq false }
    end

    context "when other is not a model" do
      let(:other) { 700 }

      it { is_expected.to eq false }
    end
  end

  context "when type is incorrect" do
    let(:test_class) do
      Struct.new(:key) do
        include Conflow::Redis::Model

        field :params, :linked_list
      end
    end

    let(:expected_error) do
      "Unknown type: linked_list. Should be one of: [:hash, :array, :value, :sorted_set, :set, :raw_value]"
    end

    it "raises error" do
      expect { test_class }.to raise_error(ArgumentError, expected_error)
    end
  end

  describe ".has_many" do
    let(:test_class) { model_with_relation }

    it "defines #worker_ids array" do
      expect(instance.worker_ids).to eq []
    end

    context "when there are some associated objects" do
      before do
        worker = related_model.new("test_worker")
        worker.name = "Heavy"
        instance.worker_ids << worker.id
      end

      it "has access to them" do
        expect(instance.workers).to all(satisfy { |worker| worker.name == "Heavy" })
      end
    end
  end

  describe "#assign_attributes" do
    subject { instance.assign_attributes(records: %w[a b t], status: :assigned) }

    it { expect { subject }.to change { instance.records.to_a }.to %w[a b t] }
    it { expect { subject }.to change { instance.status.to_s }.to "assigned" }
  end

  describe "#destroy!" do
    subject { instance.destroy! }

    let(:test_class) { model_with_relation }
    let(:related_instance) { related_model.new("other_key").tap { |model| model.name = "Hardworking" } }

    before do
      instance.status = "Superb"
      instance.worker_ids << related_instance.key
    end

    let(:expected_keys) { %w[test_key:status test_key:worker_ids other_key:name] }

    it { is_expected.to match_array expected_keys }
    it { expect { subject }.to change { expected_keys.map { |key| redis.exists key } }.to all(eq(false)) }
  end
end
