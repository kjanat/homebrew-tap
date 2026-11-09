# frozen_string_literal: true

cask "svg" do
  on_macos do
    on_arm do
      version "0.3.0"
      sha256 "d7a16b9588c76806d7c74f65cb796d2009d0d9ccccea76b0be6a48a433375319"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "0.3.0"
      sha256 "a599ce927f0d613b7dad5c60400b5969bb86ed963f8cb97b447615a3967e391f"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "0.3.0"
      sha256 "dbe06531b5e9af3660f352b4873dac2883fb0dcab0568404aa399592f8861978"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "0.3.0"
      sha256 "fa8a035c528a0967724b4b675633905943c4e4cd8da39d31c38cc09b5c633eb9"
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
