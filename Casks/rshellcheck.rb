# frozen_string_literal: true

cask "rshellcheck" do
  arch arm: "aarch64", intel: "x86_64"

  on_macos do
    on_arm do
      version "1.2.0"
      sha256 "fe28d158e3b14101aa2e00f1d389093cf7b1873a710b5304a655df88c5a392bc"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "1.2.0"
      sha256 "73a6caad08fa2ca8d93cc911d80bb77380d711ccc0c03c588af2cc7b97fb0861"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "1.2.0"
      sha256 "ff393d9d353022dacf183971a9ef63a322ed18a6136f7a369309effb6b38b037"
      url "https://github.com/kjanat/shellcheck-rs/releases/download/rshellcheck-v#{version}/rshellcheck-#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "1.2.0"
      sha256 "e785cb702d883a9dcafd694fd3c0bd5e0591f0a4b2f0e880dab5bd8ee71355ac"
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
