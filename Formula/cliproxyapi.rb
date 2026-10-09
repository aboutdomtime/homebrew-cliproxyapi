class Cliproxyapi < Formula
  desc "OpenAI/Gemini/Claude/Codex-compatible API router"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  version "8.0.22"
  license "MIT"

  depends_on :macos

  if Hardware::CPU.arm?
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.22/CLIProxyAPI_8.0.22_darwin_aarch64.tar.gz"
    sha256 "2ccb94b03ce4feefa2b839f7a0eaae90951d4131572c075099f56c94d15a7f50"
  else
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.22/CLIProxyAPI_8.0.22_darwin_amd64.tar.gz"
    sha256 "53dfa8d458e224c926314aff437f06524731af9f880844ee79b40c8fece86d65"
  end

  livecheck do
    url "https://github.com/router-for-me/CLIProxyAPI/releases/latest"
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
            exec "#{libexec}/cli-proxy-api" "$@"
            ;;
        esac
      done

      config="${CLIPROXYAPI_CONFIG:-#{etc}/cliproxyapi/config.yaml}"
      if [[ -f "$config" ]]; then
        exec "#{libexec}/cli-proxy-api" -config "$config" "$@"
      fi

      exec "#{libexec}/cli-proxy-api" "$@"
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
        #{pkgshare}/config.example.yaml

      Start manually:
        cliproxyapi

      Override config:
        cliproxyapi -config /path/to/config.yaml
    EOS
  end

  test do
    output = shell_output("#{bin}/cliproxyapi --help 2>&1")
    assert_match "CLIProxyAPI Version: 8.0.22", output
  end
end
