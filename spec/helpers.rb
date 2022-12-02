# frozen_string_literal: true

require 'fileutils'

module Helpers
  def delete_file(path)
    FileUtils.rm_rf(path)
  end

  def create_empty_file(path)
    FileUtils.touch(path)
  end

  def create_dir(path)
    FileUtils.mkdir_p(path)
  end

  def stub_empty_ok(url)
    stub_request(:get, url).to_return(status: 200, body: '', headers: {})
  end

  def stub_sized_ok(url, size)
    stub_request(:get, url).to_return(status: 200, body: '0' * size, headers: { 'Content-Length' => size.to_s })
  end

  def stub_content_ok(url, content)
    stub_request(:get, url).to_return(status: 200, body: content, headers: { 'Content-Length' => content.size.to_s })
  end

  def stub_infinite_redirect(url)
    stub_request(:get, url).to_return(status: 302, body: '', headers: { 'Location' => url })
  end

  def stub_client_error(url)
    stub_request(:get, url).to_return(status: 422, body: '', headers: {})
  end

  def stub_server_error(url)
    stub_request(:get, url).to_return(status: 500, body: '', headers: {})
  end
end
