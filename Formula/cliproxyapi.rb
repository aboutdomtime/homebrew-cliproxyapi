class Cliproxyapi < Formula
  desc "OpenAI/Gemini/Claude/Codex-compatible API router"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  version "8.0.56"
  license "MIT"

  depends_on :macos

  if Hardware::CPU.arm?
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.56/CLIProxyAPI_8.0.56_darwin_aarch64.tar.gz"
    sha256 "356bb4c64d3ef0238192481be1d0efde6d495bba74bdefe60badbc5dce698799"
  else
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.56/CLIProxyAPI_8.0.56_darwin_amd64.tar.gz"
    sha256 "68a40da80b87c8e4d4e66453e04a44183767ea593e1070661ed92e3855558b51"
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
    assert_match "CLIProxyAPI Version: 8.0.56", output
  end
end
