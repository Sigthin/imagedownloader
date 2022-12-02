# frozen_string_literal: true

class ImageDownloader
  class UrlDownloader
    class ClientError < StandardError
      MESSAGE = '4XX response status code'

      def message
        MESSAGE
      end
    end
  end
end
