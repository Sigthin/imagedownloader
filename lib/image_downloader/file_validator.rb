# frozen_string_literal: true

require_relative 'file_validator/empty_path_error'
require_relative 'file_validator/empty_file_error'
require_relative 'file_validator/not_a_file_error'
require_relative 'file_validator/too_big_file_error'

class ImageDownloader
  class FileValidator
    MAX_FILE_SIZE = 100_000_000 # 100MB

    EXCEPTIONS = [
      EmptyFileError,
      EmptyPathError,
      NotAFileError,
      TooBigFileError
    ].freeze

    def initialize(file_path)
      @file_path = file_path
    end

    def call
      check_file_path
      check_file_present
      check_file_content_present
      check_file_max_size
    end

    private

    attr_reader :file_path

    def check_file_path
      raise EmptyPathError if file_path.nil? || file_path.empty?
    end

    def check_file_present
      raise NotAFileError unless File.file?(file_path)
    end

    def check_file_content_present
      raise EmptyFileError if File.size(file_path).zero?
    end

    def check_file_max_size
      raise TooBigFileError if File.size(file_path) > MAX_FILE_SIZE
    end
  end
end
