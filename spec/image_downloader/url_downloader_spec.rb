# frozen_string_literal: true

require './lib/image_downloader/url_downloader'

describe ImageDownloader::UrlDownloader do
  describe '#call' do
    let(:logger) { Logger.new('/dev/null') }
    let(:url) { 'http://localhost/' }
    let(:described_object) { described_class.new(url, logger) }
    subject { described_object.call }

    context 'having infinite redirects' do
      before do
        stub_infinite_redirect(url)
      end

      it 'raises error' do
        expect { subject }.to raise_error(ImageDownloader::UrlDownloader::TooManyRedirectsError)
      end
    end

    context 'having client error (wrong query)' do
      before do
        stub_client_error(url)
      end

      it 'raises client error and reports invalidness' do
        expect { subject }.to raise_error(ImageDownloader::UrlDownloader::ClientError)
        expect(described_object).not_to be_valid
      end
    end

    context 'having server error' do
      before do
        stub_server_error(url)
      end

      it 'raises server error and reports invalidness' do
        expect { subject }.to raise_error(ImageDownloader::UrlDownloader::ServerError)
        expect(described_object).not_to be_valid
      end
    end

    context 'running out of disk space' do
      let(:remain_disk_space) { 1000 }
      let(:chunk_size) { remain_disk_space * 2 }

      before do
        allow(Sys::Filesystem).to receive_message_chain(:stat, :bytes_available).and_return(remain_disk_space)
        stub_sized_ok(url, chunk_size)
      end

      it 'raises out of disk space error and reports invalidness' do
        expect { subject }.to raise_error(ImageDownloader::UrlDownloader::OutOfDiskSpaceError)
        expect(described_object).not_to be_valid
      end
    end

    context 'downloading too big document' do
      let!(:original_max_size) { ImageDownloader::UrlDownloader::MAX_SIZE }
      let(:new_max_size) { 1000 }

      before do
        ImageDownloader::UrlDownloader.send(:remove_const, 'MAX_SIZE')
        ImageDownloader::UrlDownloader.const_set('MAX_SIZE', new_max_size)
        stub_sized_ok(url, new_max_size + 1)
      end

      it 'raises too big document error and reports invalidness' do
        expect { subject }.to raise_error(ImageDownloader::UrlDownloader::TooBigDocumentError)
        expect(described_object).not_to be_valid
      end

      after do
        ImageDownloader::UrlDownloader.send(:remove_const, 'MAX_SIZE')
        ImageDownloader::UrlDownloader.const_set('MAX_SIZE', original_max_size)
      end
    end

    context 'when invalid' do
      let(:url) { 'http://localhost/document' }
      let(:tempfile_path) { described_object.send(:tempfile).path }

      before do
        described_object.instance_variable_set('@valid', false)
        stub_sized_ok(url, 1)
      end

      it 'deletes tempfile if previously created' do
        subject
        expect(File.file?(tempfile_path)).to be_falsey
      end
    end

    context 'empty image' do
      let(:url) { 'http://localhost/image' }
      let(:tempfile_path) { described_object.send(:tempfile).path }

      before do
        stub_empty_ok(url)
      end

      it 'deletes tempfile if previously created' do
        subject
        expect(File.file?(tempfile_path)).to be_falsey
      end
    end

    context 'happy path' do
      let(:name) { 'image' }
      let(:downloaded_file_path) { ImageDownloader::UrlDownloader::WRITE_TO + name }
      let(:content) { '0' }
      let(:url) { "http://localhost/path/to/#{name}" }
      let(:tempfile_path) { described_object.send(:tempfile).path }

      before do
        stub_content_ok(url, content)
      end

      it 'saves the image from created tempfile to file name' do
        subject
        expect(File.file?(tempfile_path)).to be_falsey
        expect(File.file?(downloaded_file_path)).to be_truthy
        expect(File.size(downloaded_file_path)).to eq content.size
        expect(File.read(downloaded_file_path)).to eq content
      end

      it 'reports success' do
        expect(logger).to receive(:info).with("downloaded: #{url.inspect}")
        subject
      end

      after do
        delete_file(downloaded_file_path)
      end
    end

    context 'out of redirects' do
      let(:described_object) { described_class.new(url, logger, 0) }

      it 'raises error' do
        expect { subject }.to raise_error(ImageDownloader::UrlDownloader::TooManyRedirectsError)
      end
    end
  end
end
