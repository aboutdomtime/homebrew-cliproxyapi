#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "net/http"
require "pathname"
require "tmpdir"
require "uri"

UPSTREAM_REPO = "router-for-me/CLIProxyAPI"
FORMULA_PATH = Pathname.new(__dir__).join("../Formula/cliproxyapi.rb").expand_path

def github_get(url, redirects: 5, &block)
  raise "too many redirects for #{url}" if redirects.negative?

  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "application/vnd.github+json"
  request["User-Agent"] = "homebrew-cliproxyapi-updater"
  if ENV["GITHUB_TOKEN"]&.length&.positive? && ["api.github.com", "github.com"].include?(uri.host)
    request["Authorization"] = "Bearer #{ENV.fetch("GITHUB_TOKEN")}"
  end

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(request) do |response|
      case response
      when Net::HTTPSuccess
        return block.call(response)
      when Net::HTTPRedirection
        location = response["location"]
        raise "redirect without location for #{url}" if location.nil? || location.empty?

        return github_get(location, redirects: redirects - 1, &block)
      else
        raise "GET #{url} failed: #{response.code} #{response.message}"
      end
    end
  end
end

def fetch_json(url)
  github_get(url) { |response| JSON.parse(response.body) }
end

def download_to(url, path)
  github_get(url) do |response|
    File.open(path, "wb") do |file|
      response.read_body { |chunk| file.write(chunk) }
    end
  end
end

def asset_named(release, name)
  release.fetch("assets").find { |asset| asset.fetch("name") == name } ||
    raise("missing asset #{name} in #{release.fetch("html_url")}")
end

def sha256_for(asset)
  digest = asset["digest"].to_s
  return digest.delete_prefix("sha256:") if digest.start_with?("sha256:")

  Dir.mktmpdir do |dir|
    path = File.join(dir, asset.fetch("name"))
    download_to(asset.fetch("browser_download_url"), path)
    Digest::SHA256.file(path).hexdigest
  end
end

release = fetch_json("https://api.github.com/repos/#{UPSTREAM_REPO}/releases/latest")
tag = release.fetch("tag_name")
version = tag.delete_prefix("v")

arm_asset = asset_named(release, "CLIProxyAPI_#{version}_darwin_aarch64.tar.gz")
intel_asset = asset_named(release, "CLIProxyAPI_#{version}_darwin_amd64.tar.gz")
arm_sha = sha256_for(arm_asset)
intel_sha = sha256_for(intel_asset)

formula = <<~RUBY
  class Cliproxyapi < Formula
    desc "OpenAI/Gemini/Claude/Codex-compatible API router"
    homepage "https://github.com/#{UPSTREAM_REPO}"
    version "#{version}"
    license "MIT"

    depends_on :macos

    if Hardware::CPU.arm?
      url "https://github.com/#{UPSTREAM_REPO}/releases/download/#{tag}/#{arm_asset.fetch("name")}"
      sha256 "#{arm_sha}"
    else
      url "https://github.com/#{UPSTREAM_REPO}/releases/download/#{tag}/#{intel_asset.fetch("name")}"
      sha256 "#{intel_sha}"
    end

    livecheck do
      url "https://github.com/#{UPSTREAM_REPO}/releases/latest"
      strategy :github_latest
    end

    def install
      libexec.install "cli-proxy-api"
      (bin/"cliproxyapi").write <<~EOS
        #!/bin/bash
        set -euo pipefail

        for arg in "$@"; do
          case "$arg" in
            -config|--config|-config=*|--config=*)
              exec "\#{libexec}/cli-proxy-api" "$@"
              ;;
          esac
        done

        config="${CLIPROXYAPI_CONFIG:-\#{etc}/cliproxyapi/config.yaml}"
        if [[ -f "$config" ]]; then
          exec "\#{libexec}/cli-proxy-api" -config "$config" "$@"
        fi

        exec "\#{libexec}/cli-proxy-api" "$@"
      EOS
      chmod 0555, bin/"cliproxyapi"

      etc.install "config.example.yaml" => "cliproxyapi/config.yaml"
      pkgshare.install "config.example.yaml"
      doc.install "README.md", "README_CN.md"
      prefix.install "LICENSE"
    end

    def caveats
      <<~EOS
        Example config:
          \#{pkgshare}/config.example.yaml

        Start manually:
          cliproxyapi

        Override config:
          cliproxyapi -config /path/to/config.yaml
      EOS
    end

    test do
      output = shell_output("\#{bin}/cliproxyapi --help 2>&1")
      assert_match "CLIProxyAPI Version: #{version}", output
    end
  end
RUBY

FileUtils.mkdir_p(FORMULA_PATH.dirname)
FORMULA_PATH.write(formula)
