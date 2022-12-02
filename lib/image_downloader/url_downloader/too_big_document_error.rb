# frozen_string_literal: true

class ImageDownloader
  class UrlDownloader
    class TooBigDocumentError < StandardError
      MESSAGE = 'Document is too big'

      def message
        MESSAGE
      end
    end
  end
end
