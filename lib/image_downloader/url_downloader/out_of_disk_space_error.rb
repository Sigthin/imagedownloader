# frozen_string_literal: true

class ImageDownloader
  class UrlDownloader
    class OutOfDiskSpaceError < StandardError
      MESSAGE = 'Not enough disk space to wright'

      def message
        MESSAGE
      end
    end
  end
end
