# frozen_string_literal: true

module Conflow
  # Flow is a set of steps needed to complete certain task. It is composed of jobs
  # which have dependency relations with one another.
  class Flow < Conflow::Redis::Field
    include Conflow::Redis::Model
    include Conflow::Redis::Identifier

    has_many :jobs, Conflow::Job
    field :indegree, :sorted_set
  end
end
