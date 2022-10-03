require "rails_helper"

module Lookbook
  module Panels
    RSpec.describe PanelManager do
      let(:panel_name) { :example_panel }
      let(:panel_group) { :panel_group }
      let(:opts) { {partial: "path/to/partial"} }

      after do
        PanelManager.remove_all
      end

      context ".add" do
        context "with no partial path" do
          it "raises an exception" do
            expect { PanelManager.add(panel_name, panel_group) }.to raise_error PanelError
            expect { PanelManager.add(panel_name, panel_group, {foo: "bar"}) }.to raise_error PanelError
          end
        end

        context "with partial path as an option" do
          it "adds a panel to a group" do
            PanelManager.add(panel_name, panel_group, opts)
            example = PanelManager.find(panel_name)

            expect(example).to_not be nil
            expect(example.name).to eql panel_name
            expect(PanelManager.find(panel_name, panel_group)).to_not be nil
          end
        end

        context "with partial path as arg" do
          it "adds a panel to a group" do
            PanelManager.add(panel_name, panel_group, "path/to/partial")
            example = PanelManager.find(panel_name)

            expect(example).to_not be nil
            expect(example.name).to eql panel_name
            expect(PanelManager.find(panel_name, panel_group)).to_not be nil
          end
        end

        context "with options" do
          it "merges in the default options" do
            PanelManager.add(panel_name, panel_group, opts)
            example = PanelManager.find(panel_name)

            PanelManager::OPTIONS_DEFAULTS.keys.each do |key|
              expect(example).to have_key key
            end
          end

          it "doesn't overwrite existing options" do
            PanelManager.add(panel_name, panel_group, {
              partial: "path/to/partial",
              hotkey: "x"
            })
            example = PanelManager.find(panel_name)

            expect(example.partial).to eq "path/to/partial"
            expect(example.hotkey).to eq "x"
          end
        end

        context "no position specified" do
          it "adds each panel in order" do
            (1..3).each do |i|
              PanelManager.add("panel_#{i}", panel_group, opts)
            end

            example_panels = PanelManager.in_group(panel_group)

            (1..3).each do |i|
              expect(example_panels[i - 1].name).to eql "panel_#{i}".to_sym
            end
            expect(PanelManager.count).to eq 3
          end
        end

        context "with position specified" do
          it "inserts the panel in the correct position" do
            (1..3).each do |i|
              PanelManager.add("panel_#{i}", panel_group, opts)
            end

            PanelManager.add(:panel_4, panel_group, {
              partial: "path/to/partial",
              position: 2
            })

            expect(PanelManager.in_group(panel_group)[1].name).to eql :panel_4
            expect(PanelManager.count).to eq 4
          end

          it "inserts the panel at the start if the position value is zero" do
            (1..3).each do |i|
              PanelManager.add("panel_#{i}", panel_group, opts)
            end

            PanelManager.add(:panel_4, panel_group, {
              partial: "path/to/partial",
              position: 0
            })

            expect(PanelManager.in_group(panel_group).first.name).to eql :panel_4
            expect(PanelManager.count).to eq 4
          end

          it "inserts the panel at the end if the position value is greater than the number of Panel" do
            (1..3).each do |i|
              PanelManager.add("panel_#{i}", panel_group, opts)
            end

            PanelManager.add(:panel_4, panel_group, {
              partial: "path/to/partial",
              position: 100
            })

            expect(PanelManager.in_group(panel_group).last.name).to eql :panel_4
            expect(PanelManager.count).to eq 4
          end
        end
      end

      context ".update" do
        before do
          (1..3).each do |i|
            PanelManager.add("panel_#{i}", panel_group, {
              partial: "path/to/partial",
              id: "a-custom-id"
            })
          end
        end

        context "panel does not exist" do
          it "raises an exception" do
            expect { PanelManager.update("panel_oops", {id: "oops"}) }.to raise_error PanelError
          end
        end

        context "existing panel" do
          it "merges existing options with new ones" do
            new_opts = {
              id: "a-new-id",
              label: "A new label"
            }
            PanelManager.update(:panel_1, new_opts)

            expect(PanelManager.find(:panel_1)).to have_attributes(**new_opts, partial: "path/to/partial")
          end

          it "does not override the :name" do
            PanelManager.update(:panel_1, {
              name: "foo"
            })

            expect(PanelManager.find(:panel_1).name).to eq :panel_1
          end
        end
      end

      context ".remove" do
        before do
          (1..3).each do |i|
            PanelManager.add("panel_#{i}", panel_group, opts)
          end
        end

        context "panel does not exist" do
          it "raises an exception" do
            expect { PanelManager.remove("panel_oops") }.to raise_error PanelError
          end
        end

        context "existing panel" do
          it "removes it from the set of Panel" do
            PanelManager.remove(:panel_1)
            expect(PanelManager.find(:panel_1)).to be nil

            (2..3).each do |i|
              expect { PanelManager.find("panel_#{i}") }.not_to raise_error
            end
          end
        end
      end

      context ".init" do
        let(:hotkey_maker) { lambda { |data| "ctrl.#{data.hotkey_letter}" } }
        let(:data) { {hotkey_letter: "x"} }

        before do
          PanelManager.add(panel_name, panel_group, {
            partial: "path/to/partial",
            hotkey: hotkey_maker
          })
        end

        context "panel does not exist" do
          it "raises an exception" do
            expect { PanelManager.init("panel_oops", data) }.to raise_error PanelError
          end
        end

        context "panel exists" do
          it "returns a Panel instance" do
            expect(PanelManager.init(panel_name, data)).to be_an_instance_of Panel
          end

          it "resolves all callable options by calling them with the data provided" do
            name_with_data = {**data, name: panel_name.to_s}
            expect(hotkey_maker).to receive(:call).with(name_with_data)
            expect(PanelManager::OPTIONS_DEFAULTS[:label]).to receive(:call).with(name_with_data)
            PanelManager.init(panel_name, data)
          end
        end
      end

      context ".load_from_config" do
        let(:config) { Lookbook.config._system.preview_panels }

        it "loads the config" do
          PanelManager.load_from_config(config)

          config.each do |group_name, panels|
            panels.each do |panel|
              expect(PanelManager.find(panel[:name])).not_to be nil
            end
          end
        end
      end
    end
  end
end
