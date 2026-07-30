class Cliproxyapi < Formula
  desc "OpenAI/Gemini/Claude/Codex-compatible API router"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  version "7.2.109"
  license "MIT"

  depends_on :macos

  if Hardware::CPU.arm?
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v7.2.109/CLIProxyAPI_7.2.109_darwin_aarch64.tar.gz"
    sha256 "315a4d74ebafcb12ccb8a1fa65c66e9600c7e9a5554f04dcf859682ae3ce2d36"
  else
    url "https://github.com/router-for-me/CLIProxyAPI/releases/download/v7.2.109/CLIProxyAPI_7.2.109_darwin_amd64.tar.gz"
    sha256 "f7876a6d48d23cd3327dacbe7837d8d1319580b2d847186a0d56f73535d4924f"
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
    assert_match "CLIProxyAPI Version: 7.2.109", output
  end
end
