require "rails_helper"

RSpec.describe Lookbook::PanelsConfigStore do
  context "instance" do
    let(:opts) { {partial: "path/to/partial"} }
    let(:defaults) { Lookbook::PanelsConfigStore::DEFAULTS }
    let(:config) { Lookbook::PanelsConfigStore.new }

    before do
      config = Lookbook::PanelsConfigStore.new # standard:disable Lint/UselessAssignment
    end

    context ".add" do
      context "with no partial path" do
        it "raises an exception" do
          expect { config.add(:panel_name, :panel_group) }.to raise_error Lookbook::ConfigError
          expect { config.add(:panel_name, :panel_group, {foo: "bar"}) }.to raise_error Lookbook::ConfigError
        end
      end

      context "with partial path as an option" do
        it "adds a panel to a group" do
          config.add(:panel_name, :panel_group, opts)
          example = config.find(:panel_name)

          expect(example).to_not be nil
          expect(example.name).to eql :panel_name
          expect(config.find(:panel_name, :panel_group)).to_not be nil
        end
      end

      context "with partial path as arg" do
        it "adds a panel to a group" do
          config.add(:panel_name, :panel_group, "path/to/partial")
          example = config.find(:panel_name)

          expect(example).to_not be nil
          expect(example.name).to eql :panel_name
          expect(config.find(:panel_name, :panel_group)).to_not be nil
        end
      end

      context "with options" do
        it "merges in the default options" do
          config.add(:panel_name, :panel_group, opts)
          example = config.find(:panel_name)

          defaults.keys.each do |key|
            expect(example).to have_key key
          end
        end

        it "doesn't overwrite existing options" do
          config.add(:panel_name, :panel_group, {
            partial: "path/to/partial",
            hotkey: "x"
          })
          example = config.find(:panel_name)

          expect(example.partial).to eq "path/to/partial"
          expect(example.hotkey).to eq "x"
        end
      end

      context "no position specified" do
        it "adds each panel in order" do
          (1..3).each do |i|
            config.add("panel_#{i}", :panel_group, opts)
          end

          example_panels = config.in_group(:panel_group)

          (1..3).each do |i|
            expect(example_panels[i - 1].name).to eql "panel_#{i}".to_sym
          end
          expect(config.count).to eq 3
        end
      end

      context "with position specified" do
        it "inserts the panel in the correct position" do
          (1..3).each do |i|
            config.add("panel_#{i}", :panel_group, opts)
          end

          config.add(:panel_4, :panel_group, {
            partial: "path/to/partial",
            position: 2
          })

          expect(config.in_group(:panel_group)[1].name).to eql :panel_4
          expect(config.count).to eq 4
        end

        it "inserts the panel at the start if the position value is zero" do
          (1..3).each do |i|
            config.add("panel_#{i}", :panel_group, opts)
          end

          config.add(:panel_4, :panel_group, {
            partial: "path/to/partial",
            position: 0
          })

          expect(config.in_group(:panel_group).first.name).to eql :panel_4
          expect(config.count).to eq 4
        end

        it "inserts the panel at the end if the position value is greater than the number of Panel" do
          (1..3).each do |i|
            config.add("panel_#{i}", :panel_group, opts)
          end

          config.add(:panel_4, :panel_group, {
            partial: "path/to/partial",
            position: 100
          })

          expect(config.in_group(:panel_group).last.name).to eql :panel_4
          expect(config.count).to eq 4
        end
      end
    end

    context ".update" do
      before do
        (1..3).each do |i|
          config.add("panel_#{i}", :panel_group, {
            partial: "path/to/partial",
            id: "a-custom-id"
          })
        end
      end

      context "panel does not exist" do
        it "raises an exception" do
          expect { config.update("panel_oops", {id: "oops"}) }.to raise_error Lookbook::ConfigError
        end
      end

      context "existing panel" do
        it "merges existing options with new ones" do
          new_opts = {
            id: "a-new-id",
            label: "A new label"
          }
          config.update(:panel_1, new_opts)

          expect(config.find(:panel_1)).to have_attributes(**new_opts, partial: "path/to/partial")
        end

        it "does not override the :name" do
          config.update(:panel_1, {
            name: "foo"
          })

          expect(config.find(:panel_1).name).to eq :panel_1
        end

        context "position specified" do
          it "moves the panel to the correct position" do
            config.update(:panel_1, {
              position: 2
            })

            expect(config.in_group(:panel_group)[1].name).to eq :panel_1
          end
        end
      end
    end

    context ".remove" do
      before do
        (1..3).each do |i|
          config.add("panel_#{i}", :panel_group, opts)
        end
      end

      context "panel does not exist" do
        it "raises an exception" do
          expect { config.remove("panel_oops") }.to raise_error Lookbook::ConfigError
        end
      end

      context "existing panel" do
        it "removes it from the set of panels" do
          config.remove(:panel_1)
          expect(config.find(:panel_1)).to be nil

          (2..3).each do |i|
            expect { config.find("panel_#{i}") }.not_to raise_error
          end
        end
      end

      context ".load" do
        let(:config_data) { Lookbook::Config::PANELS }

        it "loads the config" do
          config.load(config_data)

          config_data.each do |group_name, group_panels|
            group_panels.each do |panel|
              expect(config.find(panel[:name])).not_to be nil
            end
          end
        end
      end
    end

    context "class" do
      let(:config_store) { Lookbook::PanelsConfigStore }

      context ".resolve_config" do
        let(:data) { {hotkey_letter: "x"} }
        let(:config) do
          {name: "example", label: "a label", hotkey: lambda { |data| "ctrl.#{data.hotkey_letter}" }}
        end

        it "resolves any procs in the config with the provided data" do
          resolved = config_store.resolve_config(config, data)

          expect(resolved).to have_attributes({
            label: "a label",
            hotkey: "ctrl.x"
          })
        end
      end
    end
  end
end
