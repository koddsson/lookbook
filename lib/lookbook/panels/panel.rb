module Lookbook
  module Panels
    class Panel
      ID_PREFIX = "lookbook-panel"

      attr_reader :name, :partial, :hotkey, :disabled, :show, :copy, :locals

      def initialize(name:, partial:, label: nil, hotkey: nil, disabled: false, show: true, copy: nil, locals: {}, **kwargs)
        @name = name.to_sym
        @partial = partial
        @label = label
        @hotkey = hotkey
        @disabled = disabled
        @show = show
        @copy = copy
        @locals = locals
      end

      def dom_id
        @dom_id ||= "#{ID_PREFIX}-#{@name.to_s.parameterize.dasherize}"
      end

      def label
        @label ||= @name.to_s.titleize
      end
    end
  end
end
