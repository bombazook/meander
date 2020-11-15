# frozen_string_literal: true

require_relative 'plain'
require 'delegate'
require 'forwardable'
module Meander
  ##
  # This class is a mutable version of Meander::Plain
  #
  # All keys you alter will be keep up to date if dependend objects updated
  # == Usage
  # === Nesting value updates
  #   a = {}
  #   m = Meander::Mutable.new(a)
  #   a['key'] = 1
  #   m.key       # => 1
  # === Value overloading
  #   a = {}
  #   m = Meander::Mutable.new(a)
  #   m.key = 1
  #   m.key       # => 1
  #   a           # => {}
  # === Deep value overloading
  #   a = {a: {b: {c: 1}}}
  #   m = Meander::Mutable.new(a)
  #   m.a.b.merge!({d: 2})
  #   m.a.b.c     # => 1
  #   m.a.b.d     # => 2
  #   a           # => {a: {b: {c: 1}}}
  #   a[:a][:b][:c] = 3
  #   m.a.b.c     # => 3
  # ==== Notice
  # Meander::Mutable support multiple object references
  #   a = {a: 1}
  #   m = Meander::Mutable.new(a)
  #   b = {b: 2}
  #   m.merge!(b)
  #   a[:a] = 3
  #   b[:b] = 4
  #   m.a # => 3  # Value is up to date
  #   m.b # => 4  # This value is also up to date
  # You can also initialize Meander::Mutable with multiple nested hashes
  #   a = {a: 1}
  #   b = {b: 2}
  #   m = Meander::Mutable.new(a, b)
  #   a[:a] = 3
  #   b[:b] = 4
  #   m.a # => 3  # Value is up to date
  #   m.b # => 4  # This value is also up to date
  class Mutable < ::Thor::CoreExt::HashWithIndifferentAccess
    include CommonMethods
    include Enumerable

    def self.own_keys_cover_class
      klass = self
      @own_keys_cover_class ||= Class.new(Plain) do
        self.cover_class = klass
      end
    end

    def initialize(required = {}, *args)
      __setobj__(required, *args)
      @own_keys = self.class.own_keys_cover_class.new
    end

    def __getobj__
      @delegate
    end

    def __setobj__(*args)
      @delegate = []
      @delegate += args
      @delegate
    end

    def merge!(hsh)
      @delegate ||= []
      @delegate.unshift hsh
    end

    def key?(key)
      @own_keys.key?(key) || delegated_key?(key)
    end

    def dup
      self.class.new(*__getobj__)
    end

    def each(*args, &block)
      return enum_for(:each) unless block_given?

      deep_call.each { |i| i.each(*args, &block) }
    end

    def keys
      map { |k, _| convert_key(k) }
    end

    def [](key)
      val = nil
      if @own_keys.key? key
        val = @own_keys[key]
      else
        val = get_delegated_value(key)
        if val.is_a?(Hash)
          val = self.class.new(val)
          self[key] = val
        end
      end
      val
    end

    def respond_to_missing?(method_name, include_private = false)
      @own_keys.respond_to?(method_name) || delegated_key?(method_name) || super
    end

    def method_missing(method_name, *args, &block)
      if @own_keys.respond_to?(method_name) || block_given?
        @own_keys.send method_name, *args, &block
      elsif delegated_key?(method_name)
        self[method_name]
      else
        super
      end
    end

    def kind_of?(klass)
      (self.class.cover_class == klass) || __getobj__.all?(klass)
    end

    alias is_a? kind_of?

    extend Forwardable
    def_delegators :@own_keys, :[]=

    private

    def deep_call(origin: self)
      stack = []
      if origin.is_a?(Array)
        stack.unshift(*origin)
        origin = stack.pop
      end
      Enumerator.new do |yielder|
        while origin
          own_keys = origin.instance_variable_get(:@own_keys)
          if own_keys
            yielder.yield own_keys
            stack.unshift(*origin.__getobj__)
            origin = stack.pop
          else
            yielder.yield origin
            origin = stack.empty? ? nil : stack.pop
          end
        end
        self
      end
    end

    def delegated_key?(key)
      key = convert_key(key)
      deep_call(origin: __getobj__).any? do |i|
        i.keys.any? { |k| convert_key(k) == key }
      end
    end

    def get_delegated_value(key)
      value = nil
      key = convert_key(key)
      deep_call(origin: __getobj__).detect do |i|
        i.keys.any? { |k| convert_key(k) == key && value = i[k] }
      end
      value
    end
  end
end
