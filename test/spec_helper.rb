$:.unshift File.expand_path '../../lib', __FILE__

require 'bundler'
Bundler.require :default, :development, :test
require 'minitest/pride'
require 'minitest/autorun'
require 'angelo'
require 'angelo/minitest/helpers'
Celluloid.logger.level = ::Logger::ERROR
include Angelo::Minitest::Helpers

TEST_APP_ROOT = File.expand_path '../test_app_root', __FILE__

CK = 'ANGELO_CONCURRENCY' # concurrency key
DC = 5                    # default concurrency
CONCURRENCY = ENV.key?(CK) ? ENV[CK].to_i : DC

# https://gist.github.com/tkareine/739662
#
class CountDownLatch
  attr_reader :count

  def initialize(to)
    @count = to.to_i
    raise ArgumentError, "cannot count down from negative integer" unless @count >= 0
    @lock = Mutex.new
    @condition = ConditionVariable.new
  end

  def count_down
    @lock.synchronize do
      @count -= 1 if @count > 0
      @condition.broadcast if @count == 0
    end
  end

  def wait
    @lock.synchronize do
      @condition.wait(@lock) while @count > 0
    end
  end

end

module Cellper

  @@stop = false
  @@testers = {}

  def define_action sym, &block
    define_method sym, &block
  end

  def remove_action sym
    remove_method sym
  end

  def unstop!
    @@stop = false
  end

  def stop!
    @@stop = true
  end

  def stop?
    @@stop
  end

  def testers; @@testers; end

end

class Reactor
  include Celluloid::IO
  extend Cellper
end

$reactor = Reactor.new

class ActorPool
  include Celluloid
  extend Cellper
end

$pool = ActorPool.pool size: CONCURRENCY

def obj
  {'foo' => 'bar', 'bar' => 123.4567890123456, 'bat' => true}
end

def obj_s
  obj.keys.reduce({}){|h,k| h[k] = obj[k].to_s; h}
end
