module Lookbook
  class PanelsConfigStore
    DEFAULTS = {
      label: lambda { |data| data.name.titleize },
      hotkey: nil,
      disabled: false,
      show: true,
      copy: nil,
      locals: {}
    }

    ERROR_SCOPE = "panels.config"

    def initialize(config = nil)
      @config = Store.new({}, recursive: true)
      load(config)
    end

    def add(name, group_name, *args)
      if find(name)
        raise ConfigError.new("panel with name '#{name}' already exists", ERROR_SCOPE)
      else
        panel = build_config(name, group_name, *args)
        insert_at_position(group_name, panel.position, panel)
      end
    end

    def update(name, opts = {})
      panel = find(name)
      if panel.present?
        panel.merge!(opts.except(:name, :position))
        if opts.key?(:position)
          remove(name)
          insert_at_position(panel.group, opts[:position], panel)
        end
      else
        not_found!(name)
      end
    end

    def remove(name)
      @config.each do |group_name, panels|
        return true unless panels.reject! { |p| p.name == name.to_sym }.nil?
      end
      not_found!(name)
    end

    def load(config)
      config.to_h.each do |group_name, panels|
        panels.each do |opts|
          add(opts[:name], group_name, opts.except(:name))
        end
      end
    end

    def find(name, group_name = nil)
      panels(group_name).find { |p| p.name == name.to_sym }
    end

    def count(group_name = nil)
      panels(group_name).count
    end

    def in_group(name)
      @config[name.to_sym] ||= []
    end

    def panels(group_name = nil)
      @config.reduce([]) do |result, (name, group_panels)|
        result.push(*group_panels) if group_name.nil? || name == group_name.to_sym
      end
    end

    def self.resolve_config(opts, data)
      if opts[:name].present?
        data = data.is_a?(Store) ? data : Store.new(data)
        data.name = opts[:name].to_s
        resolved = opts.transform_values do |value|
          value.respond_to?(:call) ? value.call(data) : value
        end
        Store.new(resolved)
      else
        raise ConfigError.new(":name key is required when resolving config", ERROR_SCOPE)
      end
    end

    protected

    def insert_at_position(group_name, position, opts)
      group_panels = in_group(group_name)
      index = insert_index(position, group_panels.count)
      group_panels.insert(index, opts.except!(:position))
    end

    def insert_index(position, items_count)
      index = position == 0 ? 1 : (position || 0).to_int
      last_position = items_count + 1
      index = last_position if index > last_position
      index - 1
    end

    def build_config(name, group_name, *args)
      opts = if args.many? && args.last.is_a?(Hash)
        args.last.merge({partial: args.first})
      elsif args.any?
        args.first.is_a?(String) ? {partial: args.first} : args.first
      else
        {}
      end
      if opts[:partial].present?
        opts[:name] = name.to_sym
        opts[:group] = group_name.to_sym
        Store.new(DEFAULTS.merge(opts))
      else
        raise ConfigError.new("panels must define a partial path", ERROR_SCOPE)
      end
    end

    def not_found!(name)
      raise ConfigError.new("could not find panel named '#{name}'", ERROR_SCOPE)
    end
  end
end
