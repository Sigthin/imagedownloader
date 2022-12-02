# frozen_string_literal: true

class ImageDownloader
  class FileValidator
    class EmptyFileError < StandardError
      MESSAGE = 'File is empty'

      def message
        MESSAGE
      end
    end
  end
end
