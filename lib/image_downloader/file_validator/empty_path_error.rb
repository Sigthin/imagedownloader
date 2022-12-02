# frozen_string_literal: true

class ImageDownloader
  class FileValidator
    class EmptyPathError < StandardError
      MESSAGE = 'File path is empty'

      def message
        MESSAGE
      end
    end
  end
end
