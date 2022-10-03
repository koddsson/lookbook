require "rails_helper"

module Lookbook
  module Panels
    RSpec.describe Panel do
      let(:panel_name) { "example_panel" }
      let(:partial_path) { "path/to/partial" }

      context ".new" do
        it "requires :name and :partial" do
          expect { Panel.new(name: panel_name) }.to raise_error ArgumentError
          expect { Panel.new(partial: partial_path) }.to raise_error ArgumentError
          expect { Panel.new(name: panel_name, partial: partial_path) }.not_to raise_error
        end
      end

      context ".name" do
        it "is a symbol" do
          panel = Panel.new(name: panel_name, partial: partial_path)

          expect(panel.name).to be_a Symbol
          expect(panel.name).to eql panel_name.to_sym
        end
      end

      context ".dom_id" do
        it "is suitable for use as an DOM id" do
          test_names = ["with spaces", :symbol_with_underscores, "12324245", "UPPERCASE-mix"]
          test_names.each do |name|
            panel = Panel.new(name: name, partial: partial_path)
            dom_id = panel.dom_id

            expect(dom_id).to be_a String
            expect(dom_id).to include(name.to_s.parameterize.dasherize)
            expect(dom_id).not_to match(/\s/)
            expect(dom_id).not_to match(/[A-Z]/)
            expect(dom_id).not_to match(/^\d/)
            expect(dom_id).not_to match(/_/)
          end
        end
      end

      context ".label" do
        it "returns the supplied label if present" do
          panel = Panel.new(name: panel_name, partial: partial_path, label: "Label test")

          expect(panel.label).to eq "Label test"
        end

        it "generates one from the name if not present" do
          panel = Panel.new(name: panel_name, partial: partial_path)

          expect(panel.label).to eq panel_name.titleize
        end
      end

      context "with defaults" do
        it "has the expected other attributes" do
          panel = Panel.new(name: panel_name, partial: partial_path)

          expect(panel).to have_attributes({
            partial: partial_path,
            hotkey: nil,
            disabled: false,
            show: true,
            copy: nil,
            locals: {}
          })
        end
      end

      context "with overrides" do
        it "has the expected other attributes" do
          overrides = {
            partial: partial_path,
            hotkey: "f",
            disabled: true,
            show: false,
            copy: "copy me",
            locals: {bar: "baz"}
          }

          overrides.each do |key, value|
            opts = {name: panel_name, partial: partial_path}
            opts[key] = value
            panel = Panel.new(**opts)
            expect(panel.public_send(key)).to eql value
          end
        end
      end
    end
  end
end
