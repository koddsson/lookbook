module Lookbook
  module Panels
    module PanelManager
      OPTIONS_DEFAULTS = {
        label: lambda { |data| data.name.titleize }
      }

      class << self
        def add(name, group_name, *args)
          if exists?(name)
            raise error("panel with name '#{name}' already exists")
          else
            panel = build_opts(name, *args)
            group_panels = in_group(group_name)
            index = insert_index(panel.position, group_panels.count)
            group_panels.insert(index, panel)
          end
        end

        def update(name, opts = {})
          panel = find(name)
          if panel.present?
            panel.merge!(opts.except(:name))
          else
            not_found!(name)
          end
        end

        def remove(name)
          @groups.each do |group_name, panels|
            return true unless panels.reject! { |p| p[:name] == name.to_sym }.nil?
          end
          not_found!(name)
        end

        def init(name, data)
          opts = find(name)
          if opts.present?
            Panel.new(**resolve_opts(name, opts, data))
          else
            not_found!(name)
          end
        end

        def init_all(*args)
          group_name = nil
          if args.first.is_a?(Hash)
            data = args.first
          else
            group_name = args.first
            data = args[1] || {}
          end
          in_group(group_name).map do |opts|
            init(opts.name, data)
          end
        end

        def load_from_config(groups)
          groups.each do |group_name, panels|
            panels.each do |opts|
              add(opts[:name], group_name, opts.except(:name))
            end
          end
        end

        def find(name, group_name = nil)
          panels(group_name).find { |p| p.name == name.to_sym }
        end

        def remove_all
          @groups = Store.new
        end

        def count(group_name = nil)
          panels(group_name).count
        end

        def in_group(name)
          groups[name.to_sym] ||= []
        end

        private

        def exists?(name)
          !!find(name)
        end

        def groups
          @groups ||= Store.new
        end

        def panels(group_name = nil)
          groups.reduce([]) do |result, (name, group_panels)|
            result.push(*group_panels) if group_name.nil? || name == group_name.to_sym
          end
        end

        def insert_index(position, items_count)
          index = position == 0 ? 1 : (position || 0).to_int
          last_position = items_count + 1
          index = last_position if index > last_position
          index - 1
        end

        def build_opts(name, *args)
          opts = if args.many? && args.last.is_a?(Hash)
            args.last.merge({partial: args.first})
          elsif args.any?
            args.first.is_a?(String) ? {partial: args.first} : args.first
          else
            {}
          end
          if opts[:partial].present?
            opts[:name] = name.to_sym
            Store.new(OPTIONS_DEFAULTS.merge(opts))
          else
            raise error("panels must provide a partial path")
          end
        end

        def resolve_opts(name, opts, data)
          data = Store.new(data)
          data.name = name.to_s
          opts.transform_values do |value|
            value.respond_to?(:call) ? value.call(data) : value
          end
        end

        def error(message)
          PanelError.new(message)
        end

        def not_found!(name)
          raise error("could not find panel named '#{name}'")
        end
      end
    end
  end
end
