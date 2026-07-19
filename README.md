# Homebrew CLIProxyAPI Tap

Personal Homebrew tap for [router-for-me/CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI).

## Install

```sh
brew tap aboutdomtime/cliproxyapi
brew install cliproxyapi
```

The formula installs the upstream `cli-proxy-api` binary as `cliproxyapi`.

By default, `cliproxyapi` uses:

```sh
$(brew --prefix)/etc/cliproxyapi/config.yaml
```

Override it with:

```sh
cliproxyapi -config /path/to/config.yaml
```

## Updating

`.github/workflows/update-formula.yml` checks the latest upstream GitHub release on a schedule and commits formula updates when a new release is available.
