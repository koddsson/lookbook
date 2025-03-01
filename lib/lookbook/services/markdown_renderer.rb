require "redcarpet"

module Lookbook
  class MarkdownRenderer < Service
    attr_reader :text, :opts

    def initialize(text, opts = {})
      @text = text
      @opts = opts.to_h
    end

    def call
      clean_text = ActionViewAnnotationsStripper.call(text)
      md = Redcarpet::Markdown.new(LookbookMarkdownRenderer, opts)
      md.render(clean_text).html_safe
    end

    class LookbookMarkdownRenderer < Redcarpet::Render::HTML
      def block_code(code, language = "ruby")
        line_numbers = language.to_s.end_with? "-numbered"
        ApplicationController.render(Lookbook::Code::Component.new(**{
          source: code,
          language: language.to_s.chomp("-numbered"),
          line_numbers: line_numbers
        }), layout: nil)
      end
    end
  end
end
