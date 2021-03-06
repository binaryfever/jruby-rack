require 'jruby/rack'

module JRuby
  module Rack
    class MerbServletHelper < ::JRuby::Rack::ServletHelper
      attr_reader :merb_environment, :merb_root

      def initialize(servlet_context = nil)
        super

        @merb_root = @servlet_context.getInitParameter('merb.root')
        @merb_root ||= '/WEB-INF'
        @merb_root = expand_root_path @merb_root

        @merb_environment = @servlet_context.getInitParameter('merb.environment')
        @merb_environment ||= 'production'
      end

      def load_merb
        require 'rubygems'
        require 'merb-core'
        require 'merb-core/rack'

        register_servlet_adapter
        load_servlet_sessions
        start_merb
      end

      def load_servlet_sessions
        logdev.write('Loading Merb servlet sessions')
        require 'jruby/rack/merb_servlet_session'
      end

      def register_servlet_adapter
        logdev.write('Registering Merb servlet adapter')
        Merb::Rack::Adapter.register %w{servlet}, :Servlet
      end

      def start_merb
        logdev.write('Starting Merb')
        Merb.start :merb_root => merb_root,
                   :environment => merb_environment,
                   :adapter => 'servlet',
                   :disabled_components => [:signals],
                   :log_stream => logdev
      end
    end

    class MerbFactory
      def self.new
        MerbServletHelper.instance.load_merb
        ::Rack::Builder.new { run ::Merb::Config[:app] }.to_app
      end
    end
  end
end

# Merb likes to hardcode things into the Merb:: namespace.
module Merb
  module Rack
    class Servlet
      def self.start(opts={})
        ::Merb.logger.warn!("Using Java servlet adapter")
      end
    end
  end
end
