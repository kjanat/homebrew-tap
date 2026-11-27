# frozen_string_literal: true

cask "svg" do
  on_macos do
    on_arm do
      version "0.5.2"
      sha256 "0d6ad43cd282744782ebb081510efbcadc8e988cf892ed4fdd7d099202b7ae71"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "0.5.2"
      sha256 "2cc69d11a7e567336218a1db3f1dd3bf333ec2f04a68ab708d2090d4d65e42f0"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "0.5.2"
      sha256 "7b97a8c93febb761c3ca19ac256b92ddba3dad84e953ed5fba3e8bef707282c4"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "0.5.2"
      sha256 "da485af52ec4b81f29ac59746255c60c9196e8db0c509c1d3ded36b6fce5f160"
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
