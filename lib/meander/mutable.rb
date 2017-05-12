require 'meander/plain'
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
  # Meander::Mutable support only one up to date object reference
  #   a = {a: 1}
  #   m = Meander::Mutable.new(a)
  #   b = {b: 2}
  #   m.merge!(b)
  #   a[:a] = 3
  #   b[:b] = 4
  #   m.a # => 3  # Value is up to date
  #   m.b # => 2  # Attention! Value remains unchanged
  class Mutable < Delegator
    include CommonMethods

    def self.own_keys_cover_class
      klass = self
      @own_keys_cover_class ||= Class.new(Plain) do
        self.cover_class = klass
      end
    end

    def initialize(obj = {})
      super
      @delegate_sd_obj = obj
      @own_keys = self.class.own_keys_cover_class.new
    end

    def __getobj__
      @delegate_sd_obj
    end

    def __setobj__(obj)
      @delegate_sd_obj = obj
    end

    def key?(key)
      @own_keys.key?(key) ||
        begin
          obj = __getobj__
          obj.key?(key.to_s) || obj.key?(key.to_sym)
        end
    end

    def is_a?(klass)
      klass.ancestors.include?(Hash) || super
    end

    def keys
      origin = __getobj__
      own = @own_keys
      [(origin && origin.keys), (own && own.keys)].flatten
                                                  .compact.map(&:to_s).uniq
    end

    def [](key)
      val = nil
      if @own_keys.key? key
        val = @own_keys[key]
      else
        val = get_delegated_value key
        if val.is_a?(Hash)
          val = self.class.new(val)
          self[key] = val
        end
      end
      val
    end

    def respond_to_missing?(method, include_private = false)
      @own_keys.respond_to?(method) || delegated_key?(method.to_s) || super
    end

    def method_missing(method, *args, &block)
      if @own_keys.respond_to?(method) || block_given?
        @own_keys.send method, *args, &block
      elsif delegated_key? method
        define_getter method
        send method, *args, &block
      else
        super
      end
    end

    extend Forwardable
    def_delegator :@own_keys, :[]=

    private

    def delegated_key?(key)
      __getobj__.keys.map(&:to_s).include? key.to_s
    end

    def get_delegated_value(key)
      delegated = __getobj__
      if key.respond_to?(:to_s) && delegated.key?(key.to_s)
        delegated[key.to_s]
      elsif key.respond_to?(:to_sym) && delegated.key?(key.to_sym)
        delegated[key.to_sym]
      else
        delegated[key]
      end
    end
  end
end
