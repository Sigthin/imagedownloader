# frozen_string_literal: true

require 'uri'

class ImageDownloader
  class UrlValidator
    MAX_URL_LENGTH = 4_000 # for NGINX servers

    def initialize(url)
      @url = url
    end

    def call
      return false if url.nil? || url.empty?

      return false if url.size > MAX_URL_LENGTH

      uri_parsed?
    end

    private

    attr_reader :url

    def uri_parsed?
      (http? || https?) && host_present?
    rescue URI::InvalidURIError
      false
    end

    def uri
      @uri ||= URI.parse(url)
    end

    def http?
      uri.instance_of?(URI::HTTP)
    end

    def https?
      uri.instance_of?(URI::HTTPS)
    end

    def host_present?
      !uri.host.nil?
    end
  end
end
