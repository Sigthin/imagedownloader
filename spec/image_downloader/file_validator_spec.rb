# frozen_string_literal: true

require './lib/image_downloader/file_validator'

describe ImageDownloader::FileValidator do
  describe '#call' do
    subject { ImageDownloader::FileValidator.new(file_path).call }

    context 'when no file path provided' do
      let(:file_path) { nil }

      it 'raises empty file path error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::EmptyPathError)
      end
    end

    context 'when empty file path provided' do
      let(:file_path) { '' }

      it 'raises empty file path error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::EmptyPathError)
      end
    end

    context 'when file is missing' do
      let(:file_path) { './example_urls.txt' }

      before do
        delete_file(file_path)
      end

      it 'raises not a file error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::NotAFileError)
      end
    end

    context 'when not a file' do
      let(:file_path) { './example_urls.txt' }

      before do
        delete_file(file_path)
        create_dir(file_path)
      end

      it 'raises not a file error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::NotAFileError)
      end

      after do
        delete_file(file_path)
      end
    end

    context 'given file is empty' do
      let(:file_path) { './example_urls.txt' }

      before do
        delete_file(file_path)
        create_empty_file(file_path)
      end

      it 'raises empty file error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::EmptyFileError)
      end

      after do
        delete_file(file_path)
      end
    end

    context 'given file is too big' do
      let!(:original_file_max_size) { ImageDownloader::FileValidator::MAX_FILE_SIZE }
      let(:new_file_max_size) { 1000 }
      let(:file_path) { './example_urls.txt' }

      before do
        delete_file(file_path)
        ImageDownloader::FileValidator.send(:remove_const, 'MAX_FILE_SIZE')
        ImageDownloader::FileValidator.const_set('MAX_FILE_SIZE', new_file_max_size)
        File.write(file_path, '0' * (new_file_max_size + 1))
      end

      it 'raises too big file error' do
        expect { subject }.to raise_error(ImageDownloader::FileValidator::TooBigFileError)
      end

      after do
        ImageDownloader::FileValidator.send(:remove_const, 'MAX_FILE_SIZE')
        ImageDownloader::FileValidator.const_set('MAX_FILE_SIZE', original_file_max_size)
        delete_file(file_path)
      end
    end

    context 'given valid file' do
      let(:file_path) { './example_urls.txt' }
      let(:urls) { 'http://localhost' }

      before do
        delete_file(file_path)
        File.write(file_path, urls)
      end

      it 'works fine' do
        expect { subject }.not_to raise_error
      end

      after do
        delete_file(file_path)
      end
    end
  end
end
