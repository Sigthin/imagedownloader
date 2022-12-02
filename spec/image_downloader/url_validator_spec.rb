# frozen_string_literal: true

require './lib/image_downloader/url_validator'

describe ImageDownloader::UrlValidator do
  describe '#call' do
    context 'when no url provided' do
      let(:url) { nil }
      subject { ImageDownloader::UrlValidator.new(url).call }

      it 'reports false' do
        expect(subject).to be_falsey
      end
    end

    context 'when empty url provided' do
      let(:url) { '' }
      subject { ImageDownloader::UrlValidator.new(url).call }

      it 'reports false' do
        expect(subject).to be_falsey
      end
    end

    context 'when invalid url provided' do
      let(:invalid_urls) do
        [
          'http:||example.com',
          'http://:1/asdf',
          'http::1/asdf',
          'http:///example.com',
          'http:/',
          ' http://localhost',
          'http://localhost ',
          'asd!$@.com',
          'javascript:alert("spam")',
          'http://',
          "http://test.com\n<script src=\"nasty.js\""
        ]
      end

      it 'reports false' do
        url_validation_results = invalid_urls.map { |url| ImageDownloader::UrlValidator.new(url).call }
        expect(url_validation_results.uniq.size).to eq(1)
        expect(url_validation_results.uniq.first).to be_falsey
      end
    end

    context 'when valid url provided' do
      let(:url) { 'https://www.example.com' }
      subject { ImageDownloader::UrlValidator.new(url).call }

      it 'reports true' do
        expect(subject).to be_truthy
      end
    end
  end
end
