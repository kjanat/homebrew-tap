# frozen_string_literal: true

cask "rshellcheck" do
  arch arm: "aarch64", intel: "x86_64"

  on_macos do
    on_arm do
      version "1.0.0"
      sha256 "c6030ee2c47b3318aaf59c9a788ad38cb6be873b2cea8114f50ec77ad0391cc2"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "1.0.0"
      sha256 "5a58444326faba435191f424e2aed1a7cc0038a3530e29bcc4e1560bcad2cde0"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "1.0.0"
      sha256 "7cc44c1ad4b67e61a3489f3a45f4100feef66b31a5b35926acb3325d4fcf693b"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "1.0.0"
      sha256 "c1c305d318e174f0e322c9bf93a40bede355bc102eedfcde0792a670e01ef986"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-x86_64-unknown-linux-musl.tar.gz"
    end
  end

  name "rshellcheck"
  desc "Rust port of the ShellCheck shell script analyzer"
  homepage "https://github.com/kjanat/shellcheck-rs"

  livecheck do
    url :url
    regex(/^rshellcheck-v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  on_macos do
    binary "rshellcheck-#{version}-#{arch}-apple-darwin/rshellcheck"
  end
  on_linux do
    binary "rshellcheck-#{version}-#{arch}-unknown-linux-musl/rshellcheck"
  end

  preflight_steps do
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}"]
    end
  end

  zap :not_required
end
