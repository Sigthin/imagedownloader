# frozen_string_literal: true

class ImageDownloader
  class FileValidator
    class TooBigFileError < StandardError
      MESSAGE = 'File is too big'

      def message
        MESSAGE
      end
    end
  end
end
