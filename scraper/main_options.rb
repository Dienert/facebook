require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class Optparse

  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.server = ''

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: facebook.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Mandatory argument.
      opts.on("-s", "--server SERVER",
              "Require the SERVER before executing your script, example: v121p060") do |server|
        options.server << server
      end

      # Mandatory argument.
      opts.on("-n", "--number_jobs NUMBER",
              "Number of Jobs to be collected, default: no limit") do |number_jobs|
        options.number_jobs << number_jobs
      end

      # Boolean switch.
      opts.on("-l", "--[no-]error-log", "Only download error logs, jobs are not processed") do |l|
        options.only_error_log = l
      end

      opts.separator ""
      opts.separator "Common options:"

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts ::Version.join('.')
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end  # parse()

end  # class Optparse
