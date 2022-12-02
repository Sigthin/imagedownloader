# frozen_string_literal: true

class ImageDownloader
  class UrlEnqueuer
    SEPARATOR = ' '

    def initialize(file_path, queue, logger)
      @file_path = file_path
      @queue = queue
      @logger = logger
    end

    def call
      file.each(SEPARATOR, &method(:process_line))
    ensure
      close_file
    end

    private

    attr_reader :file_path,
                :queue,
                :logger

    def process_line(line)
      process_url(line.strip)
    end

    def process_url(url)
      if valid?(url)
        queue << url
      else
        logger.warn("invalid url: #{url.inspect}")
      end
    end

    def valid?(url)
      UrlValidator.new(url).call
    end

    def file
      @file ||= File.new(file_path)
    end

    def close_file
      return unless @file

      @file.close
    end
  end
end
