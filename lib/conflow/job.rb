# frozen_string_literal: true

module Conflow
  # Represents conflow job.
  class Job < Conflow::Redis::Field
    include Conflow::Redis::Model
    include Conflow::Redis::Identifier

    has_many :successors, Conflow::Job
    field :params, :hash
    field :status, :value # 0 - pending, 1 - finished

    def initialize(*)
      super
      self.status = 0
    end
  end
end