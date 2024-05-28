require 'rspec'
ENV['APP_ENV'] = 'test'

RSpec.configure do |config|
  config.order            = 'random'
end
