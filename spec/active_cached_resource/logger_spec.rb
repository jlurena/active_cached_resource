require "spec_helper"
require "stringio"

RSpec.describe ActiveCachedResource::Logger do
  let(:model_name) { "TestModel" }
  let(:output) { StringIO.new }
  let(:logger) { described_class.new(model_name) }

  before do
    allow($stdout).to receive(:write).and_wrap_original do |original, message|
      output.write(message)
    end
  end

  described_class::COLORS.excluding(:reset).each do |severity, color_code|
    it "logs debug messages with color" do
      logger.public_send(severity, "This is a message")
      output.rewind
      log_output = output.read

      expect(log_output).to include(color_code)
      expect(log_output).to include("#{severity.upcase} [CACHE][ACR][#{model_name}] This is a message")
      expect(log_output).to include(described_class::COLORS[:reset])
    end
  end
end
