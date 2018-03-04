# frozen_string_literal: true

RSpec.describe Conflow::Redis::Model, redis: true do
  let(:test_class) do
    Struct.new(:key) do
      extend Conflow::Redis::Model

      field :params, :hash
      field :records, :array
      field :status, :value
    end
  end

  let(:instance) { test_class.new("test_key") }

  it "defines proper methods" do
    expect(instance).to respond_to(:params, :params=, :records, :records=, :status, :status=)
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
end
