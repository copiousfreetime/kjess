if RUBY_VERSION >= '1.9.2' then
  require 'simplecov'
  puts "Using coverage!"
  SimpleCov.start if ENV['COVERAGE']
end

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require "minitest/reporters"
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new
#MiniTest::Reporters.use! MiniTest::Reporters::ProgressReporter.new
require 'kjess'
require 'utils'
require 'thread'
