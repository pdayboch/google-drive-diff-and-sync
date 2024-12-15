# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch # Enable branch coverage
  add_filter '/spec/'     # Exclude test files from coverage
end

require 'rspec'
ENV['APP_ENV'] = 'test'

RSpec.configure do |config|
  config.order = 'random'
end
