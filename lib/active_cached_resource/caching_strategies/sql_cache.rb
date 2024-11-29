require_relative "base"

module ActiveCachedResource
  module CachingStrategies
    class SQLCache < Base
      def initialize(model, options = {})
        super()
        @model = model
        @batch_clear_size = options.fetch(:batch_clear_size, 1000)
      end

      protected

      def read_raw(key)
        record = @model.where(key: key).where(@model.arel_table[:expires_at].gt(Time.current)).first
        record&.value
      end

      def write_raw(key, value, options = {})
        expires_at = Time.current + options.fetch(:expires_in)

        @model.create({key: key, value: value, expires_at: expires_at})
      end

      def clear_raw(pattern)
        @model.where(@model.arel_table[:key].matches("#{pattern}%")).in_batches(of: @batch_clear_size) do |batch|
          batch.delete_all
        end
      end
    end
  end
end
