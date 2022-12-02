# frozen_string_literal: true

class ImageDownloader
  class UrlDownloader
    class TooManyRedirectsError < StandardError
      MESSAGE = 'Too many redirections'

      def message
        MESSAGE
      end
    end
  end
end
