# frozen_string_literal: true

require 'logger'
require './lib/image_downloader/url_downloader'
require './lib/image_downloader/url_download_runner'

describe ImageDownloader::UrlDownloadRunner do
  describe '#call' do
    let!(:original_max_size) { ImageDownloader::UrlDownloader::MAX_SIZE }
    let(:url1) { 'http://url1' }
    let(:url2) { 'http://url2' }
    let(:logger) { Logger.new('/dev/null') }
    let(:described_object) { described_class.new(queue, logger) }
    subject { described_object.call }

    context 'given non-empty queue' do
      let(:queue) { SizedQueue.new(2) }
      before do
        queue.push(url1)
        queue.push(url2)
        stub_empty_ok(url1)
        stub_empty_ok(url2)
      end

      it 'consumes queue until it is empty' do
        subject
        expect(queue).to be_empty
      end

      context 'trying to download too big document' do
        let(:new_max_size) { 1000 }
        before do
          queue.clear
          queue.push(url1)
          ImageDownloader::UrlDownloader.send(:remove_const, 'MAX_SIZE')
          ImageDownloader::UrlDownloader.const_set('MAX_SIZE', new_max_size)
          stub_sized_ok(url1, new_max_size + 1)
        end

        it 'reports too big document error' do
          expect(logger).to receive(:warn).with(/#{ImageDownloader::UrlDownloader::TooBigDocumentError::MESSAGE}/)
          subject
        end

        after do
          ImageDownloader::UrlDownloader.send(:remove_const, 'MAX_SIZE')
          ImageDownloader::UrlDownloader.const_set('MAX_SIZE', original_max_size)
        end
      end

      context 'getting too many redirects' do
        before do
          queue.clear
          queue.push(url1)
          stub_infinite_redirect(url1)
        end

        it 'reports too many redirects error' do
          expect(logger).to receive(:warn).with(/#{ImageDownloader::UrlDownloader::TooManyRedirectsError::MESSAGE}/)
          subject
        end
      end

      context 'getting client error' do
        before do
          queue.clear
          queue.push(url1)
          stub_client_error(url1)
        end

        it 'reports client error' do
          expect(logger).to receive(:warn).with(/#{ImageDownloader::UrlDownloader::ClientError::MESSAGE}/)
          subject
        end
      end

      context 'getting server error' do
        before do
          queue.clear
          queue.push(url1)
          stub_server_error(url1)
        end

        it 'reports server error' do
          expect(logger).to receive(:warn).with(/#{ImageDownloader::UrlDownloader::ServerError::MESSAGE}/)
          subject
        end
      end

      context 'having not enough disk space' do
        before do
          queue.clear
          queue.push(url1)
          allow(ImageDownloader::UrlDownloader).to receive(:new).and_raise(ImageDownloader::UrlDownloader::OutOfDiskSpaceError)
        end

        it 'reports not enough disk space error' do
          expect(logger).to receive(:warn).with(/#{ImageDownloader::UrlDownloader::OutOfDiskSpaceError::MESSAGE}/)
          subject
        end
      end
    end
  end
end
