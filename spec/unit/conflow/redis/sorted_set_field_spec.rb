# frozen_string_literal: true

RSpec.describe Conflow::Redis::SortedSetField, redis: true do
  let(:sorted_set_field)  { described_class.new("test.zset") }
  let(:filled_sorted_set) { sorted_set_field.tap { |field| field.add(best: 0, last: 10, tie: 0) } }

  shared_examples "action changing sorted set" do |expected_sorted_set|
    it { expect { subject }.to change { sorted_set_field.to_h }.to(expected_sorted_set) }
  end

  describe "#add" do
    subject { sorted_set_field.add(friend: 3, stranger: 100) }
    it_behaves_like "action changing sorted set", "friend" => 3, "stranger" => 100
  end

  describe "#[]" do
    subject { filled_sorted_set[:last] }
    it { is_expected.to eq 10 }
  end

  describe "#delete" do
    subject { filled_sorted_set.delete("tie") }
    it_behaves_like "action changing sorted set", "last" => 10, "best" => 0
  end

  describe "#overwrite" do
    subject { filled_sorted_set.overwrite(super: 1, new: 10) }
    it_behaves_like "action changing sorted set", "super" => 1, "new" => 10
  end
end
