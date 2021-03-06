$:.unshift File.expand_path '../../../lib', __FILE__

require 'bundler'
Bundler.require :default, :development, :profile

require 'angelo'
require 'angelo/tilt/erb'
require 'angelo/mustermann'

class Foo < Angelo::Base
  include Angelo::Tilt::ERB
  include Angelo::Mustermann

  TEST = {foo: "bar", baz: 123, bat: false}.to_json
  PONG = 'pong'

  @@avg = 0.0

  def pong; PONG; end
  def foo; params[:foo]; end
  def time_ms; Time.now.to_f * 1000.0; end

  before do
    # info "request: #{request.method} #{request.path}"
    @foo = request.path
    @timing = time_ms
  end

  after do
    # info "timing: #{time_ms - @timing}ms"
    @@reqs ||= 1
    if @@avg == 0.0
      @@avg = time_ms - @timing
    else
      @@avg = (@@avg * @@reqs) + (time_ms - @timing)
      @@reqs += 1
      @@avg = @@avg / @@reqs
      info "avg (#{@@reqs}): #{@@avg}" if @@reqs % 100 == 0
    end
  end

  get '/' do
    @name = params[:name]
    @host = request.headers['Host']
    erb :index, locals: {zzz: 'word'}
  end

  get '/ping' do
    # debug "@foo: #{@foo}"
    pong
  end

  post '/foo' do
    foo
  end

  post '/bar' do
    content_type :json
    params
  end

  post '/emit' do
    websockets.each {|ws| ws.write TEST}
    params.to_json
  end

  websocket '/ws' do |s|
    websockets << s

    # don't do this!
    #
    # while msg = s.read
    #
    # instead, do this!
    #
    s.on_message do |msg|
      5.times { s.write TEST }
      s.write foo.to_json
    end
  end

  websocket '/:foo/echo' do |s|
    begin

      # again, don't do this!
      #
      # while msg = s.read
      #
      # instead, do this!
      #
      s.on_message do |msg|
        s.write "#{params[:foo]} - #{msg}"
      end
    rescue Reel::SocketError => rse
      debug "socket: #{rse.message}"
    end
  end

end

Foo.run unless $0 == 'irb'
