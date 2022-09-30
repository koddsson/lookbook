module Lookbook
  module Params
    class Editor::Component < Lookbook::BaseComponent
      renders_many :fields, ->(input:, description: nil, **attrs) do
        @field_count = @field_count + 1
        @descriptions = true if description.present?
        input_config = @inputs[input.gsub("-", "_").to_sym]
        Lookbook::Params::Field::Component.new(input: input, description: description, index: @field_count, config: input_config, **attrs)
      end

      def initialize(inputs: {}, **html_attrs)
        @inputs = inputs
        @field_count = -1
        @descriptions = false
        super(**html_attrs)
      end

      def before_render
        fields
      end

      protected

      def alpine_component
        "paramsEditorComponent"
      end
    end
  end
end