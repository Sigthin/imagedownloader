# frozen_string_literal: true

require 'logger'

require_relative 'image_downloader/file_validator'
require_relative 'image_downloader/url_validator'
require_relative 'image_downloader/url_enqueuer'
require_relative 'image_downloader/url_download_runner'
require_relative 'image_downloader/url_downloader'

class ImageDownloader
  MAX_QUEUE_SIZE = 5
  MAX_DOWNLOAD_THREADS_COUNT = 5

  def initialize(file_path, logger = Logger.new($stdout))
    @file_path = file_path
    @logger = logger
  end

  def call
    validate_file_path
    start_enqueuer_thread
    start_downloader_threads
    wait_threads
  end

  private

  attr_reader :file_path,
              :logger

  def queue
    @queue ||= SizedQueue.new(MAX_QUEUE_SIZE)
  end

  def threads
    @threads ||= []
  end

  def validate_file_path
    FileValidator.new(file_path).call
  end

  def start_enqueuer_thread
    threads << Thread.new do
      UrlEnqueuer.new(file_path, queue, logger).call
    end
  end

  def start_downloader_threads
    MAX_DOWNLOAD_THREADS_COUNT.times do
      threads << Thread.new { UrlDownloadRunner.new(queue, logger).call }
    end
  end

  def wait_threads
    threads.each(&:join)
  end
end
