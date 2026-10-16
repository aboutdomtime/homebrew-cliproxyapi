class Cliproxyapi < Formula
  desc "OpenAI/Gemini/Claude/Codex-compatible API router"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  version "8.0.31"
  license "MIT"

  depends_on :macos

  if Hardware::CPU.arm?
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.31/CLIProxyAPI_8.0.31_darwin_aarch64.tar.gz"
    sha256 "36e193a737c4821aa122cf35c293c13f2b16c10d56d4ac4b19ced197fab19a79"
  else
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.31/CLIProxyAPI_8.0.31_darwin_amd64.tar.gz"
    sha256 "4a3b17a82856260c67ef2c246538075e41e553591b21a7681314d309ceed8922"
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
    assert_match "CLIProxyAPI Version: 8.0.31", output
  end
end
