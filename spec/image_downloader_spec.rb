# frozen_string_literal: true

require './lib/image_downloader'

describe ImageDownloader do
  describe '#call' do
    let(:logger) { Logger.new('/dev/null') }
    let(:path) { './example_urls.txt' }
    let(:described_object) { described_class.new(path, logger) }
    subject { described_object.call }

    context 'file is missing' do
      before do
        delete_file(path)
      end

      it 'raises not a file error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::NotAFileError)
      end
    end

    context 'path is a directory' do
      before do
        delete_file(path)
        create_dir(path)
      end

      it 'raises not a file error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::NotAFileError)
      end

      after do
        delete_file(path)
      end
    end

    context 'file is empty' do
      before do
        delete_file(path)
        create_empty_file(path)
      end

      it 'raises file validation error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::EmptyFileError)
      end

      after do
        delete_file(path)
      end
    end

    context 'file is too big' do
      let!(:original_file_max_size) { ImageDownloader::FileValidator::MAX_FILE_SIZE }
      let(:new_file_max_size) { 1000 }

      before do
        delete_file(path)
        ImageDownloader::FileValidator.send(:remove_const, 'MAX_FILE_SIZE')
        ImageDownloader::FileValidator.const_set('MAX_FILE_SIZE', new_file_max_size)
        File.write(path, '0' * (new_file_max_size + 1))
      end

      it 'raises file validation error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::TooBigFileError)
      end

      after do
        ImageDownloader::FileValidator.send(:remove_const, 'MAX_FILE_SIZE')
        ImageDownloader::FileValidator.const_set('MAX_FILE_SIZE', original_file_max_size)
        delete_file(path)
      end
    end

    context 'file is present and not empty' do
      before do
        delete_file(path)
        File.write(path, '0')
      end

      it 'reads file just fine' do
        expect { subject }.not_to raise_error
      end

      it 'works in multithreaded mode' do
        expect(Thread).to receive(:new).and_call_original.exactly(1 + ImageDownloader::MAX_DOWNLOAD_THREADS_COUNT).times
        subject
      end

      after do
        delete_file(path)
      end
    end

    context 'valid urls are present in file' do
      let(:image_file_name1) { 'image_file_name1' }
      let(:image_file_name2) { 'image_file_name2' }
      let(:url1) { "http://url1/#{image_file_name1}" }
      let(:url2) { "http://url2/#{image_file_name2}" }
      let(:urls) { "#{url1} #{url2}" }
      let(:image1_content) { '0' * 10 }
      let(:image2_content) { '0' * 20 }
      let(:downloaded_file_path1) { ImageDownloader::UrlDownloader::WRITE_TO + image_file_name1 }
      let(:downloaded_file_path2) { ImageDownloader::UrlDownloader::WRITE_TO + image_file_name2 }

      before do
        stub_content_ok(url1, image1_content)
        stub_content_ok(url2, image2_content)
        delete_file(path)
        File.write(path, urls)
      end

      it 'downloads images' do
        subject
        expect(File.file?(downloaded_file_path1)).to be_truthy
        expect(File.file?(downloaded_file_path2)).to be_truthy
        expect(File.size(downloaded_file_path1)).to eq image1_content.size
        expect(File.size(downloaded_file_path2)).to eq image2_content.size
        expect(File.read(downloaded_file_path1)).to eq image1_content
        expect(File.read(downloaded_file_path2)).to eq image2_content
      end

      it 'reports success' do
        expect(logger).to receive(:info).with("downloaded: #{url1.inspect}")
        expect(logger).to receive(:info).with("downloaded: #{url2.inspect}")
        subject
      end

      after do
        delete_file(path)
        delete_file(downloaded_file_path1)
        delete_file(downloaded_file_path2)
      end
    end
  end
end
