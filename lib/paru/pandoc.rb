module Paru

  require 'yaml'

  # Pandoc is a wrapper around the pandoc system. See
  # <http://pandoc.org/README.html> for details about pandoc.  This file is
  # basically a straightforward translation from command line program to ruby
  # class

  class Pandoc

    def initialize &block
      @options = {}
      configure(&block) if block_given?
      @option_sep = "\t"
    end

    def configure &block
      instance_eval(&block)
      self
    end

    # Converts input string to output string using the pandoc invocation
    # configures in this Pandoc instance.
    def convert input
      output = ''
      IO.popen(to_command(@option_sep), 'r+') do |p|
        p << input
        p.close_write
        output << p.read
      end
      output
    end
    alias << convert

    def to_command option_sep = "\t\\\n"
      "pandoc\t#{to_option_string option_sep}"
    end

    def to_option_string option_sep
      options_arr = []
      @options.each do |option, value|
        option_string = "--#{option.to_s.gsub '_', '-'}"

        case value
        when TrueClass then
          # Flags don't have a value, only its name
          # For example: --standalone
          options_arr.push "#{option_string}"
        when FalseClass then
          # Skip this option; consider a flag with value false as unset
        when Array then
          # This option can occur multiple times: list each with its value.
          # For example: --css=main.css --css=print.css
          options_arr.push value.map {|val| "#{option_string}=#{val.to_s}"}.join(option_sep)
        else
          # All options that aren't flags and can occur only once have the
          # same pattern: --option=value
          options_arr.push "#{option_string}=#{value.to_s}"
        end
      end
      options_arr.join(option_sep)
    end

    # Pandoc has a number of command line options. Most are simple options,
    # like flags, that can be set only once. Other options can occur more than
    # once, such as the css option: to add more than one css file to a
    # generated standalone html file, use the css options once for each
    # stylesheet to include. Other options do have the pattern key[:value],
    # which can also occur multiple times, such as metadata.
    #
    # All options are specified in a pandoc_options.yaml. If it is an option
    # that can occur only once, the value of the option in that yaml file is
    # its default value. If the option can occur multiple times, its value is
    # an array with one value, the default value.
    #
    # For each of these options a method is defined as follows:
    OPTIONS = YAML.load_file File.join(__dir__, 'pandoc_options.yaml')

    OPTIONS.keys.each do |option|
      if OPTIONS[option].is_a? Array then

        # option can be set multiple times, for example adding multiple css
        # files

        default = OPTIONS[option][0]

        define_method(option) do |value = default|
          if @options[option] then
            @options[option].push value
          else
            @options[option] = [value]
          end
          self
        end

      else

        # option can be set only once, for example a flag or a template

        default = OPTIONS[option]
        define_method(option) do |value = default|
          @options[option] = value
          self
        end

      end
    end

  end

end
