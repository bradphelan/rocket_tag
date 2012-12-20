require 'spec_helper'

describe RocketTag::Configuration do
  before do
    RocketTag.configuration.reset
  end

  describe '.configure' do
    RocketTag::Configuration::VALID_CONFIG_KEYS.each do |key|
      it "sets the #{key}" do
        value = case key
        when :force_lowercase
          [true, false].sample
        else
          raise StandardError, "Don't know how to create text value for #{key}"
        end
        RocketTag.configure do |config|
          config.send "#{key}=", value
        end
        RocketTag.configuration.send(key).should eq(value)
      end
    end
  end

  RocketTag::Configuration::VALID_CONFIG_KEYS.each do |key|
    describe "##{key}" do
      it 'returns the default value' do
        RocketTag.configuration.send(key).should eq(RocketTag::Configuration.const_get("DEFAULT_#{key.upcase}"))
      end
    end
  end
end
