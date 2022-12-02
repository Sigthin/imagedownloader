# frozen_string_literal: true

require 'tempfile'
require 'sys-filesystem'
require 'net/https'

require_relative 'url_downloader/too_big_document_error'
require_relative 'url_downloader/too_many_redirects_error'
require_relative 'url_downloader/client_error'
require_relative 'url_downloader/server_error'
require_relative 'url_downloader/out_of_disk_space_error'

class ImageDownloader
  class UrlDownloader
    WRITE_TO = './downloads/'
    READ_TIMEOUT = 30
    MAX_SIZE = 3_145_728
    MAX_REDIRECTS = 5

    EXCEPTIONS = [
      TooBigDocumentError,
      TooManyRedirectsError,
      ClientError,
      ServerError,
      OutOfDiskSpaceError
    ].freeze

    EXTENSION_MAPPING = {
      'image/gif' => ['.gif'],
      'image/jpeg' => ['.jpeg', '.jpg'],
      'image/png' => ['.png'],
      'image/tiff' => ['.tiff']
    }.freeze

    DEFAULT_REQUEST_OPTIONS = {
      read_timeout: READ_TIMEOUT,
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }.freeze

    def initialize(url, logger, remain_redirects = MAX_REDIRECTS)
      @url = url
      @logger = logger
      @written = 0
      @valid = true
      @remain_redirects = remain_redirects
    end

    def call
      check_remain_redirects
      download
    end

    private

    attr_reader :url,
                :logger,
                :valid,
                :remain_redirects,
                :response

    alias valid? valid

    public :valid?

    def check_remain_redirects
      return unless remain_redirects.zero?

      @valid = false
      raise TooManyRedirectsError
    end

    def download
      Net::HTTP.start(uri.host, uri.port, **request_options) do |http|
        http.request(request) do |response|
          @response = response
          handle_response
        end
      end
    end

    def handle_response
      case response
      when Net::HTTPSuccess
        save_content
      when Net::HTTPRedirection
        handle_redirect
      else
        handle_error
      end
    end

    def save_content
      response.read_body do |chunk|
        sized_write(chunk)
      end
      report_completion
    ensure
      process_tempfile
    end

    def handle_redirect
      self.class.new(response['Location'], logger, remain_redirects - 1).call
    end

    def handle_error
      @valid = false
      case response
      when Net::HTTPClientError
        raise ClientError
      when Net::HTTPServerError
        raise ServerError
      end
    end

    def report_completion
      logger.info("downloaded: #{url.inspect}")
    end

    def sized_write(chunk)
      if available_kbs < chunk.size / 1000
        out_of_disk_space
      elsif (@written += chunk.size) > MAX_SIZE
        too_big_document
      else
        tempfile.write chunk
        tempfile.flush
      end
    end

    def out_of_disk_space
      @valid = false
      raise OutOfDiskSpaceError
    end

    def too_big_document
      @valid = false
      raise TooBigDocumentError
    end

    def file_path
      @file_path ||= WRITE_TO + document_name_with_extension
    end

    def document_name_with_extension
      return image_file_name unless extensions

      return image_file_name if document_name_extension_matches

      image_file_name + extensions.first.to_s
    end

    def document_name_extension_matches
      extensions.any? { |extension| image_file_name.end_with?(extension) }
    end

    def extensions
      @extensions ||= EXTENSION_MAPPING[response.content_type].to_a
    end

    # replace potentially dangerous characters to prevent RCE
    def image_file_name
      @image_file_name ||= uri.path.split('/').last.gsub(/[^0-9A-Za-z_.-]/, '_')
    end

    def uri
      @uri ||= URI.parse(url)
    end

    def request
      @request ||= Net::HTTP::Get.new(uri)
    end

    def request_options
      @request_options ||= DEFAULT_REQUEST_OPTIONS.
                           merge(use_ssl: uri.instance_of?(URI::HTTPS))
    end

    def process_tempfile
      return unless @tempfile

      @valid = false if tempfile.size.zero?
      tempfile.close
      valid? ? move_tempfile : delete_tempfile
    end

    def move_tempfile
      FileUtils.mv(tempfile.path, file_path)
    end

    def delete_tempfile
      FileUtils.rm(tempfile.path)
    end

    def tempfile
      @tempfile ||= Tempfile.create('', WRITE_TO)
    end

    def available_kbs
      (Sys::Filesystem.stat(WRITE_TO).bytes_available.to_f / 1000).floor
    end
  end
end
