require 'action_view/helpers/tag_helper'
require 'i18n/exceptions'
require 'i18n'

module TranslateHelper
  @show_key=false
  def self.set_show_key(x)
    @show_key = x
  end

  def self.get_show_key
    @show_key
  end
end
module I18n
  class MissingTranslation
    module Base
      attr_reader :locale, :key, :options

      def initialize(locale, key, options = nil)
        @key, @locale, @options = key, locale, options.dup || {}
        options.each { |k, v| self.options[k] = v.inspect if v.is_a?(Proc) }
      end

      def html_message
        if Rails.env.production?
          ''
        else
          key  = CGI.escapeHTML titleize(keys.last)
          path = CGI.escapeHTML keys.join('.')
          %(<span class="translation_missing" title="translation missing: #{path}">#{key}</span>)
        end
      end
    end
  end
end
module ActionView
  module Helpers
    module TranslationHelper
      def translate(key, options = {})
        missing=false
        if !Rails.env.production? && TranslateHelper.get_show_key
          raise I18n::ArgumentError if key.is_a?(String) && key.empty?
          begin
            I18n.translate!(key, :raise => true)
          rescue I18n::MissingTranslationData
            missing=true
          end
          if missing
            options.merge!(:rescue_format => :html) unless options.key?(:rescue_format)
            if html_safe_translation_key?(key)
              html_safe_options = options.dup
              options.except(*I18n::RESERVED_KEYS).each do |name, value|
                unless name == :count && value.is_a?(Numeric)
                  html_safe_options[name] = ERB::Util.html_escape(value.to_s)
                end
              end
              translation = I18n.translate(scope_key_by_partial(key), html_safe_options)
              translation.respond_to?(:html_safe) ? translation.html_safe : translation
            else
              I18n.translate(scope_key_by_partial(key), options)
            end
          else
            options.merge!(:rescue_format => :html) unless options.key?(:rescue_format)
            if html_safe_translation_key?(key)
              html_safe_options = options.dup
              options.except(*I18n::RESERVED_KEYS).each do |name, value|
                unless name == :count && value.is_a?(Numeric)
                  html_safe_options[name] = ERB::Util.html_escape(value.to_s)
                end
              end
              translation = I18n.translate(scope_key_by_partial(key), html_safe_options)

              return translation.respond_to?(:html_safe) ? translation.html_safe : translation
            else
              if options[:scope].nil?
                scope=''
              else
                scope=options[:scope]
              end
              show_key=scope+key.to_s.gsub(/\./,'--')


              if  is_trad_array? key
                result=I18n.translate(scope_key_by_partial(key), options)
                result_new=Array.new
                result.each do | value|
                  if value.nil?
                    result_new.push nil
                  else
                    result_new.push value+ "|#{show_key}|".html_safe
                  end
                end
                return result_new
              else
                return I18n.translate(scope_key_by_partial(key), options)+" |#{show_key}|".html_safe
              end
            end
          end
        end
      end
    end
  end
end