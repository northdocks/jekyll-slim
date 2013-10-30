require 'slim'

module Jekyll
  class SlimPartialTag < Liquid::Tag
    def initialize(tag_name, file, tokens)
      super
      @file = file.strip
    end

    def render(context)
      includes_dir = File.join(context.registers[:site].source, '_includes')

      if File.symlink?(includes_dir)
        return "Includes directory '#{includes_dir}' cannot be a symlink"
      end

      if @file !~ /^[a-zA-Z0-9_\/\.-]+$/ || @file =~ /\.\// || @file =~ /\/\./
        return "Include file '#{@file}' contains invalid characters or sequences"
      end

      return "File must have \".slim\" extension" if @file !~ /\.slim$/

      Dir.chdir(includes_dir) do
        choices = Dir['**/*'].reject { |x| File.symlink?(x) }
        if choices.include?(@file)
          source = File.read(@file)
          conversion = ::Slim::Template.new(context.registers[:site].config['slim'].deep_symbolize_keys) { source }.render(context.registers[:site].config)
          partial = Liquid::Template.parse(conversion)
          begin
            return partial.render!(context)
          rescue => e
            puts "Liquid Exception: #{e.message} in #{self.data["layout"]}"
            e.backtrace.each do |backtrace|
              puts backtrace
            end
            abort("Build Failed")
          end

          context.stack do
            return partial.render(context)
          end
        else
          "Included file '#{@file}' not found in _includes directory"
        end
      end
    end
  end
end

Liquid::Template.register_tag('slim', Jekyll::SlimPartialTag)
