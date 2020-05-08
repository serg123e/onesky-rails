require 'onesky/rails/client'
require 'yaml'

module Onesky
  module Rails

    class FileClient < Onesky::Rails::Client

      FILE_FORMAT = 'RUBY_YAML'
      ENCODING    = 'UTF-8'
      DIR_PREFIX  = 'onesky_'
      TRANSLATION_NOTICE = <<-NOTICE
# This file is generated by onesky-rails gem and will be overwritten at the next download
# Therefore, you should not modify this file
# If you want to modify the translation, please do it at OneSky platform
# If you still want to modify this file directly, please upload this file to OneSky platform after modification in order to update the translation at OneSky

NOTICE
      def locale_to_onesky_tmpfile( path, dir )
        filename = File.basename(path)
        content_hash = YAML.load_file(path)
        updated = false
        content_hash.keys.each do |rails_locale|
          onesky_locale = to_onesky_locale(rails_locale)
          if !(onesky_locale.eql? rails_locale)
            updated = true 
            content_hash[ onesky_locale ] = content_hash.delete( rails_locale )
            puts("replacing #{rails_locale} to #{onesky_locale} for #{filename}")
          end    
        end
        if (updated)

          tmpfile = File.join(dir, filename)
          File.open( tmpfile, 'w:utf-8' ) do |f|
            f.write( content_hash.to_yaml )
          end
          tmpfile
        else
          path
        end
      end

      def get_locale_from_file(path)
        content_hash = YAML.load_file(path)
        if (content_hash.keys.length > 1)
           raise ArgumentError.new("this version supports ony 1 language per YAML file")
        else
           content_hash.keys.first
        end
      end

      def upload(string_path, options = {})
        verify_languages!

        get_locale_files(string_path, options[:all]).map do |path|
          Dir.mktmpdir('onesky') do |dir|
            tmpfile = locale_to_onesky_tmpfile( path, dir )
            onesky_locale = to_onesky_locale( get_locale_from_file( tmpfile ) )
            filename = File.basename(path)
            puts "Uploading #{filename} (#{onesky_locale})"
            @project.upload_file(file: tmpfile, file_format: FILE_FORMAT, is_keeping_all_strings: is_keep_strings?, locale: onesky_locale)
            tmpfile
          end
        end
      end

      ##
      # Download translations from OneSky platform
      #
      # +string_path+ specify the folder path where all localization files locate
      # +options+     indicate which files to download
      #               - :base_only => base language only
      #               - :all       => all languages including base language
      #               - <empty>    => default value; translation languages
      #
      def download(string_path, options = {})
        verify_languages!

        files = get_default_locale_files(string_path).map {|path| File.basename(path)}

        locales = if options[:base_only]
          [@base_locale]
        elsif options[:all]
          [@base_locale] + @onesky_locales
        else
          @onesky_locales
        end

        locales.each do |locale|
          locale = locale.to_s
          puts "#{locale_dir(locale)}/"
          onesky_locale = to_onesky_locale( locale )
          files.each do |file|
            response = @project.export_translation(source_file_name: file, locale: onesky_locale)
            if response.code == 200
              saved_file = save_translation(response, string_path, locale, file)
              puts "  #{saved_file}"
            end
          end
        end
      end

      protected

      def locale_dir(locale)
        DIR_PREFIX + locale
      end

      def make_translation_dir(dir_path, locale)
        return dir_path if locale == @base_locale.to_s

        target_path = File.join(dir_path, locale_dir(locale))
        Dir.mkdir(target_path) unless File.directory?(target_path)
        target_path
      end

      def locale_file_name(file, to_locale)
        if File.basename(file, '.*') == @base_locale.to_s
          file.sub(@base_locale.to_s, to_locale)
        else
          file
        end
      end

      def get_locale_files(string_path, all=false, specific_locale=false)
        string_path = Pathname.new(string_path)
        locale_files_filter = generate_locale_files_filter

        paths = Dir.glob("#{string_path}/**/*.yml") | ::I18n.load_path.select{ |p| p=~ /#{string_path}.*\.yml/i } 
        paths.map do |path| # 
          relative_path = Pathname.new(path).relative_path_from(string_path).to_s
          next if locale_files_filter && !locale_files_filter.call(relative_path)
          content_hash = YAML.load_file(path)
          path if content_hash && ( all || (specific_locale && content_hash.has_key?(specific_locale)) || content_hash.has_key?(@base_locale.to_s) )
        end.compact
      end

      def get_all_locale_files(string_path)
        get_locale_files(string_path, true)
      end

      def get_default_locale_files(string_path)
        get_locale_files(string_path, false)
      end

      def save_translation(response, string_path, locale, file)
        locale_path = make_translation_dir(string_path, locale)
        target_file = locale_file_name(file, locale)

        File.open(File.join(locale_path, target_file), 'w') do |f|
          f.write(TRANSLATION_NOTICE + to_rails_locale_yml(locale,response.body.force_encoding(ENCODING)))
        end
        target_file
      end

      def is_keep_strings?
        return true unless upload_config.has_key?('is_keeping_all_strings')

        !!upload_config['is_keeping_all_strings']
      end

      def generate_locale_files_filter
        only = Array(upload_config['only'])
        except = Array(upload_config['except'])

        if only.any? && except.any?
          raise ArgumentError, "Invalid config. Can't use both `only` and `except` options."
        end

        if only.any?
          ->(path) { only.include?(path) }
        elsif except.any?
          ->(path) { !except.include?(path) }
        end
      end

      def upload_config
        @config['upload'] ||= {}
      end

    end

  end
end
