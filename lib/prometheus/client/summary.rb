# encoding: UTF-8

require 'quantile'
require 'prometheus/client/metric'

module Prometheus
  module Client
    # Summary is an accumulator for samples. It captures Numeric data and
    # provides an efficient quantile calculation mechanism.
    class Summary < Metric
      # Value represents the state of a Summary at a given point.
      class Value < Hash
        attr_accessor :sum, :total

        def initialize(estimator)
          @sum, @total = estimator.sum, estimator.observations

          values = estimator.invariants.each_with_object({}) do |i, memo|
            memo[i.quantile] = estimator.query(i.quantile)
          end

          replace(values)
        end
      end

      def type
        :summary
      end

      # Records a given value.
      def add(labels, value)
        label_set = label_set_for(labels)
        synchronize { @values[label_set].observe(value) }
      end

      # Returns the value for the given label set
      def get(labels = {})
        synchronize do
          Value.new(@values[label_set_for(labels)])
        end
      end

      # Returns all label sets with their values
      def values
        synchronize do
          @values.each_with_object({}) do |(labels, value), memo|
            memo[labels] = Value.new(value)
          end
        end
      end

      private

      def default
        Quantile::Estimator.new
      end
    end
  end
end
