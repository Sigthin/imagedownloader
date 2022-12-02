# frozen_string_literal: true

class ImageDownloader
  class FileValidator
    class NotAFileError < StandardError
      MESSAGE = 'File path is not a file (missing or directory)'

      def message
        MESSAGE
      end
    end
  end
end
