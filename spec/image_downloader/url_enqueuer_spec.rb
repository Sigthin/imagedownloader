# frozen_string_literal: true

require 'logger'
require './lib/image_downloader/url_enqueuer'
require './lib/image_downloader/url_validator'

describe ImageDownloader::UrlEnqueuer do
  describe '#call' do
    let(:url1) { 'http://url1' }
    let(:url2) { 'http://url2' }
    let(:invalid_url1) { '' }
    let(:invalid_url2) { 'invalid_url' }
    let(:urls) { "#{url1} #{url2} #{invalid_url1} #{invalid_url2}" }
    let(:path) { './example_urls.txt' }
    let(:queue) { SizedQueue.new(4) }
    let(:logger) { Logger.new('/dev/null') }
    let(:described_object) { described_class.new(path, queue, logger) }
    subject { described_object.call }

    before do
      expect(ImageDownloader::UrlValidator).to receive(:new).with(instance_of(String)).and_call_original.exactly(4).times
      delete_file(path)
      File.write(path, urls)
    end

    it 'pushes valid urls to the queue' do
      subject
      expect(queue.size).to eq 2
      queue_content = Array.new(queue.size) { queue.pop }
      expect(queue_content).to eq [url1, url2]
      expect(queue_content).not_to include(invalid_url1)
      expect(queue_content).not_to include(invalid_url2)
    end

    after do
      delete_file(path)
    end
  end
end
