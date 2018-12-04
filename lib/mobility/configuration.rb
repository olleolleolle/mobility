# frozen_string_literal: true

module Mobility
=begin

Stores shared Mobility configuration referenced by all backends.

=end
  class Configuration
    RESERVED_OPTION_KEYS = %i[backend model_class].freeze

    # Alias for mobility_accessor (defaults to +translates+)
    # @return [Symbol]
    attr_accessor :accessor_method

    def query_method=(method_name)
      error_msg = <<-EOL
query_method is no longer a global configuration option. The value can now be
set in the value of options[:query_method].
EOL
      if method_name == :i18n
        raise ArgumentError, <<-EOL
#{error_msg}

You are currently passing :i18n which is the default, so simply removing the line:

   config.query_method = :i18n

from your configuration will fix this exception.
EOL
      else
        raise ArgumentError, error_msg
      end
    end

    # Default set of options. These will be merged with any backend options
    # when defining translated attributes (with +translates+). Default options
    # may not include the keys 'backend' or 'model_class'.
    # @return [Hash]
    attr_reader :default_options

    # @param [Symbol] name Plugin name
    def plugin(name)
      attributes_class.plugin(name)
    end

    # @param [Symbol] name Plugin name
    def plugins(*names)
      names.each(&method(:plugin))
    end

    # Generate new fallbacks instance
    # @note This method will call the proc defined in the variable set by the
    # +fallbacks_generator=+ setter, passing the first argument to its `call`
    # method. By default the generator returns an instance of
    # +I18n::Locale::Fallbacks+.
    # @param fallbacks [Hash] Fallbacks hash passed to generator
    # @return [I18n::Locale::Fallbacks]
    def new_fallbacks(fallbacks = {})
      @fallbacks_generator.call(fallbacks)
    end

    # Assign proc which, passed a set of fallbacks, returns a default fallbacks
    # instance. By default this is a proc which takes fallbacks and returns an
    # instance of +I18n::Locale::Fallbacks+.
    # @param [Proc] fallbacks generator
    attr_writer :fallbacks_generator

    # Default backend to use (can be symbol or actual backend class)
    # @return [Symbol,Class]
    attr_accessor :default_backend

    # Returns set of default accessor locales to use (defaults to
    # +I18n.available_locales+)
    # @return [Array<Symbol>]
    def default_accessor_locales
      if @default_accessor_locales.is_a?(Proc)
        @default_accessor_locales.call
      else
        @default_accessor_locales
      end
    end
    attr_writer :default_accessor_locales

    def initialize
      @accessor_method = :translates
      @fallbacks_generator = lambda { |fallbacks| Mobility::Fallbacks.build(fallbacks) }
      @default_accessor_locales = lambda { Mobility.available_locales }
      @default_options = Options[{
        cache:     true,
        presence:  true,
        # Override with a symbol to define a different query method name.
        query:     true,
        # A nil key here includes the plugin so it can be optionally turned on
        # when reading an attribute using accessor options.
        fallbacks: nil
      }]
    end

    def attributes_class
      @attributes_class ||= Class.new(Attributes)
    end

    class ReservedOptionKey < Exception; end

    class Options < ::Hash
      def []=(key, _)
        if RESERVED_OPTION_KEYS.include?(key)
          raise Configuration::ReservedOptionKey, "Default options may not contain the following reserved key: #{key}"
        end
        super
      end
    end
  end
end
