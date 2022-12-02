# frozen_string_literal: true

class ImageDownloader
  class UrlDownloadRunner
    def initialize(queue, logger)
      @queue = queue
      @logger = logger
    end

    def call
      download(queue.pop) until queue.empty?
    end

    private

    attr_reader :queue,
                :logger

    def download(url)
      UrlDownloader.new(url, logger).call
    rescue *UrlDownloader::EXCEPTIONS => e
      report_document_downloading_error(url, e)
    rescue StandardError => e
      report_standard_error(url, e)
    end

    def report_document_downloading_error(url, error)
      logger.warn("#{url.inspect} - #{error.message}")
    end

    def report_standard_error(url, error)
      logger.warn("#{url.inspect} - #{error.class}: #{error.message}")
    end
  end
end
