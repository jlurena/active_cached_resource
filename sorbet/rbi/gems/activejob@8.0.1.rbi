# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `activejob` gem.
# Please instead update this file by running `bin/tapioca gem activejob`.


# :markup: markdown
# :include: ../README.md
#
# source://activejob//lib/active_job/serializers/object_serializer.rb#5
module ActiveJob; end

# = Active Job \Serializers
#
# The +ActiveJob::Serializers+ module is used to store a list of known serializers
# and to add new ones. It also has helpers to serialize/deserialize objects.
#
# source://activejob//lib/active_job/serializers/object_serializer.rb#6
module ActiveJob::Serializers; end

# Base class for serializing and deserializing custom objects.
#
# Example:
#
#   class MoneySerializer < ActiveJob::Serializers::ObjectSerializer
#     def serialize(money)
#       super("amount" => money.amount, "currency" => money.currency)
#     end
#
#     def deserialize(hash)
#       Money.new(hash["amount"], hash["currency"])
#     end
#
#     private
#
#       def klass
#         Money
#       end
#   end
#
# source://activejob//lib/active_job/serializers/object_serializer.rb#26
class ActiveJob::Serializers::ObjectSerializer
  include ::Singleton
  extend ::Singleton::SingletonClassMethods

  # Deserializes an argument from a JSON primitive type.
  #
  # @raise [NotImplementedError]
  #
  # source://activejob//lib/active_job/serializers/object_serializer.rb#44
  def deserialize(json); end

  # Serializes an argument to a JSON primitive type.
  #
  # source://activejob//lib/active_job/serializers/object_serializer.rb#39
  def serialize(hash); end

  # Determines if an argument should be serialized by a serializer.
  #
  # @return [Boolean]
  #
  # source://activejob//lib/active_job/serializers/object_serializer.rb#34
  def serialize?(argument); end

  private

  # The class of the object that will be serialized.
  #
  # @raise [NotImplementedError]
  #
  # source://activejob//lib/active_job/serializers/object_serializer.rb#50
  def klass; end

  class << self
    # source://activejob//lib/active_job/serializers/object_serializer.rb#30
    def deserialize(*_arg0, **_arg1, &_arg2); end

    # source://activejob//lib/active_job/serializers/object_serializer.rb#30
    def serialize(*_arg0, **_arg1, &_arg2); end

    # source://activejob//lib/active_job/serializers/object_serializer.rb#30
    def serialize?(*_arg0, **_arg1, &_arg2); end

    private

    def allocate; end
    def new(*_arg0); end
  end
end
