require "rails_helper"

RSpec.describe Lookbook do
  context "Data" do
    context ".data" do
      it "returns a Store instance" do
        expect(Lookbook.data).to be_a Lookbook::Store
      end
    end

    context ".data=" do
      it "overrides the existing data" do
        Lookbook.data.old_prop = true
        Lookbook.data = {
          new_prop: true
        }
        expect(Lookbook.data).to be_a Lookbook::Store
        expect(Lookbook.data.old_prop).to be nil
        expect(Lookbook.data.new_prop).to be true
      end
    end
  end

  context "Panels" do
    let(:panels_config) { Lookbook.config._panels }
    let(:default_group) { :drawer }

    context ".define_panel" do
      it "adds a panel without opts" do
        expect(panels_config).to receive(:add).with("new-panel", default_group, "path/to/partial")
        Lookbook.define_panel("new-panel", "path/to/partial")
      end

      it "adds a panel with opts" do
        opts = {label: "A nice panel"}
        expect(panels_config).to receive(:add).with("new-panel-2", default_group, "path/to/partial", opts)
        Lookbook.define_panel("new-panel-2", "path/to/partial", opts)
      end

      it "adds a panel with partial path set in opts" do
        opts = {partial: "path/to/partial"}
        expect(panels_config).to receive(:add).with("new-panel-3", default_group, opts)
        Lookbook.define_panel("new-panel-3", opts)
      end
    end
  end
end
