# frozen_string_literal: true

RSpec.describe Conflow::Redis::Model, redis: true do
  let(:test_class) do
    Struct.new(:key) do
      extend Conflow::Redis::Model

      field :params,  :hash
      field :records, :array
      field :status,  :value
      field :set,     :sorted_set
    end
  end

  let(:instance) { test_class.new("test_key") }

  it "defines proper methods" do
    expect(instance).to respond_to(:params, :params=, :records, :records=, :status, :status=)
  end

  it "defines proper getters" do
    expect(instance.params).to  be_a_kind_of(Conflow::Redis::HashField)
    expect(instance.records).to be_a_kind_of(Conflow::Redis::ArrayField)
    expect(instance.status).to  be_a_kind_of(Conflow::Redis::ValueField)
    expect(instance.set).to     be_a_kind_of(Conflow::Redis::SortedSetField)
  end

  context "when type is incorrect" do
    let(:test_class) do
      Struct.new(:key) do
        extend Conflow::Redis::Model

        field :params, :linked_list
      end
    end

    it "raises error" do
      expect { test_class }.to raise_error(ArgumentError, "Unknown type: linked_list. Should be one of: [:hash, :array]")
    end
  end

  describe ".has_many" do
    let(:related_model) do
      Struct.new(:key) do
        extend Conflow::Redis::Model
        alias_method :id, :key
        field :name, :value
      end
    end

    let(:test_class) do
      m = related_model

      Struct.new(:key) do
        extend Conflow::Redis::Model
        alias_method :id, :key
        has_many :workers, m
      end
    end

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
end
