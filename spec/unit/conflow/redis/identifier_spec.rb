# frozen_string_literal: true

RSpec.describe Conflow::Redis::Identifier, redis: true do
  let(:parent_class) do
    Struct.new(:key) do
      def self.name
        "Super::Test"
      end

      include Conflow::Redis::Identifier
    end
  end

  let(:test_class) { parent_class }

  shared_examples "parent class attributes" do
    describe ".counter_key" do
      subject { test_class.counter_key }
      it { is_expected.to eq "super:test:idcnt" }
    end

    describe ".key_template" do
      subject { test_class.key_template }
      it { is_expected.to eq "super:test:%<id>d" }
    end
  end

  include_examples "parent class attributes"

  context "when inherited" do
    let(:test_class) do
      Class.new(parent_class) do
        def self.name
          "Mediocre::Spec"
        end
      end
    end

    include_examples "parent class attributes"
  end

  describe "#initialize" do
    let(:instance) { test_class.new }

    it "assigns an id" do
      expect(instance.id).to eq 1
    end

    it "assigns a key" do
      expect(instance.key).to eq "super:test:1"
    end

    it "assigns unique id" do
      expect(instance.id).to_not eq test_class.new.id
    end

    context "when id is given" do
      let(:instance) { test_class.new(21) }

      it "preserves id" do
        expect(instance.id).to eq 21
      end
    end
  end
end
