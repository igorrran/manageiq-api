module Api
  class PhysicalServersController < BaseController
    def blink_loc_led_resource(type, id, _data)
      change_resource_state(:blink_loc_led, type, id)
    end

    def turn_on_loc_led_resource(type, id, _data)
      change_resource_state(:turn_on_loc_led, type, id)
    end

    def turn_off_loc_led_resource(type, id, _data)
      change_resource_state(:turn_off_loc_led, type, id)
    end

    def power_on_resource(type, id, _data)
      change_resource_state(:power_on, type, id)
    end

    def power_off_resource(type, id, _data)
      change_resource_state(:power_off, type, id)
    end

    def power_off_now_resource(type, id, _data)
      change_resource_state(:power_off_now, type, id)
    end

    def restart_resource(type, id, _data)
      change_resource_state(:restart, type, id)
    end

    def restart_now_resource(type, id, _data)
      change_resource_state(:restart_now, type, id)
    end

    def restart_to_sys_setup_resource(type, id, _data)
      change_resource_state(:restart_to_sys_setup, type, id)
    end

    def restart_mgmt_controller_resource(type, id, _data)
      change_resource_state(:restart_mgmt_controller, type, id)
    end

    def refresh_resource(type, id, _data = nil)
      refresh_physical_server("refresh_ems", type, id)
    end

    def apply_config_pattern_resource(type, id, data)
      apply_config(:apply_config_pattern, type, id, data)
    end

    private

    def change_resource_state(state, type, id, data = {})
      raise BadRequestError, "Must specify an id for changing a #{type} resource" unless id

      ensure_resource_exists(type, id) if single_resource?
      api_action(type, id) do |klass|
        begin
          server = resource_search(id, type, klass)
          desc = "Requested server state #{state} for #{server_ident(server)}"
          do_action(state, desc, server, data)
        rescue StandardError => err
          action_result(false, err.to_s)
        end
      end
    end

    def refresh_physical_server(state, type, id)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" unless id

      ensure_resource_exists(type, id) if single_resource?
      api_action(type, id) do |klass|
        begin
          physical_server = resource_search(id, type, klass)
          desc = "#{physical_server_ident(physical_server)} refreshing"
          do_action(state, desc, physical_server)
        rescue StandardError => err
          action_result(false, err.to_s)
        end
      end
    end

    def apply_config(state, type, id, data = {})
      raise BadRequestError, "Must specify an id for changing a #{type} resource" unless id

      if single_resource?
        ensure_resource_exists(type, id)
        ensure_customization_script_exists(data["pattern_id"])
      end

      api_action(type, id) do |klass|
        begin
          ensure_customization_script_exists(data["pattern_id"])
          server = resource_search(id, type, klass)
          desc = "Requested server state #{state} for #{server_ident(server)}"
          do_action(state, desc, server, data)
        rescue StandardError => err
          action_result(false, err.to_s)
        end
      end
    end

    def ensure_customization_script_exists(id)
      ensure_resource_exists(:customization_scripts, id)
    rescue NotFoundError
      raise NotFoundError, "Customization script not found"
    end

    def do_action(state, desc, physical_server, data = {})
      api_log_info(desc)
      task_id = queue_object_action(physical_server, desc, :args => data, :method_name => state, :role => :ems_operations)
      action_result(true, desc, :task_id => task_id)
    end

    def ensure_resource_exists(type, id)
      raise NotFoundError unless collection_class(type).exists?(id)
    end

    def server_ident(server)
      "Server instance: #{server.id} name:'#{server.name}'"
    end

    def physical_server_ident(physical_server)
      "Physical Server id:#{physical_server.id} name:'#{physical_server.name}'"
    end
  end
end
