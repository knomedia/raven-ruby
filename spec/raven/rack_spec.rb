require File::expand_path('../../spec_helper', __FILE__)
require 'raven'

describe Raven::Rack do
  it 'should capture exceptions' do
    exception = build_exception()
    env = {}
    
    Raven::Rack.should_receive(:capture_exception).with(exception, env)

    app = lambda do |e|
      raise exception
    end

    stack = Raven::Rack.new(app)
    lambda {stack.call(env)}.should raise_error(exception)
  end

  it 'should capture rack.exception' do
    exception = build_exception()
    env = {}

    Raven::Rack.should_receive(:capture_exception).with(exception, env)

    app = lambda do |e|
      e['rack.exception'] = exception
      [200, {}, ['okay']]
    end

    stack = Raven::Rack.new(app)

    stack.call(env)
  end

  it 'should capture sinatra errors' do
    exception = build_exception()
    env = {}

    Raven::Event.should_receive(:capture_rack_exception).with(exception, env)
    Raven.should_receive(:send).with(@event)

    app = lambda do |e|
      e['sinatra.error'] = exception
      [200, {}, ['okay']]
    end

    stack = Raven::Rack.new(app)

    stack.call(env)
  end

  it 'should clear context after app is called' do
    Raven::Context.current.tags[:environment] = :test

    app = lambda { |env| ['response', {}, env] }
    stack = Raven::Rack.new(app)

    response = stack.call({})

    Raven::Context.current.tags.should eq({})
  end

end
