require 'puppet/util/cli_execution'
require 'puppet/util/cli_parser'
require 'puppet/util/path_generator'

Puppet::Type.type(:jboss_exec).provide(:cli) do
  include Puppet::Util::CliExecution

  def execute_command command, arguments = nil
    # don't try to execute a command if noop
    unless resource[:noop]
      tries = 3
      try_sleep = 3
      last_error = nil
      result = nil

      tries.times do |try|
        debug("Execute command try #{try+1}/#{tries}") if try > 1
        begin
          if arguments
            parser = CliParser.new
            parsed_command = parser.parse_command command
            command = format_command PathGenerator.format_path(parsed_command[0]), parsed_command[1], arguments 
          end

          if try > 1
            debug("Sleeping for #{try_sleep} seconds")
            sleep try_sleep
          end

          result = execute_cli get_server(resource), command, false
          raise "Execution failed in execute_command" unless result['outcome'] == 'success'
          return result
        rescue => e
          last_error = e
        end
      end

      if last_error
        raise last_error
      end
      result
    end
  end
end
