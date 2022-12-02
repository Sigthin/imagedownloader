# frozen_string_literal: true

class ImageDownloader
  class UrlDownloader
    class ServerError < StandardError
      MESSAGE = '5XX response status code'

      def message
        MESSAGE
      end
    end
  end
end
