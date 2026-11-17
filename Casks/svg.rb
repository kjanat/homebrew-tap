# frozen_string_literal: true

cask "svg" do
  on_macos do
    on_arm do
      version "0.5.1"
      sha256 "5ba64465c0eab9f6d53f97b8aa7ae6a907730eca1e94bd001c7b1600e01497f1"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "0.5.1"
      sha256 "b5f82bf9394b804cb3fa72a20626d57c1360dc3f897ea099438c644da1a91ed0"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "0.5.1"
      sha256 "f9d7deff57e3693d590454d85a2a853865beaaa83ab4dc33b500ea5f9a81aecd"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "0.5.1"
      sha256 "6c11e4cd8f7429956a644b0692ab82b4890487b41793742d7e5e113123e58447"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-x86_64-unknown-linux-musl.tar.gz"
    end
  end

  name "svg"
  desc "SVG language server, formatter, and linter"
  homepage "https://github.com/kjanat/svg"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "svg-language-server"
  binary "svg-format"
  binary "svg-lint"

  preflight_steps do
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}"]
    end
  end

  zap :not_required
end
