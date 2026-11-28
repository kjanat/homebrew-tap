# frozen_string_literal: true

cask "svg" do
  on_macos do
    on_arm do
      version "0.6.0"
      sha256 "c6bd7aa2a49a09f246b7781c89b800eb79bfb18628531c579605fac40997138b"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "0.6.0"
      sha256 "1f70c757ee8291358af13907ab72b85ab57a493a8aac54084bc81c0f9e203e7f"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "0.6.0"
      sha256 "dab6c047d869d9f706a581bf22752b08fd4bee285d5f843eef4d51687d8d7bd4"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "0.6.0"
      sha256 "eba17a181e27a2dfb09f332bd661cf3fcbc390f80914c0c58cc1c2d07693fc6f"
      url "https://github.com/kjanat/svg/releases/download/v#{version}/svg-v#{version}-x86_64-unknown-linux-musl.tar.gz"
    end
  end

  name "svg"
  desc "Language server and command-line tools for SVG"
  homepage "https://github.com/kjanat/svg"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "svg-language-server"
  binary "svg-format"
  binary "svg-lint"

  # Releases through 0.5.2 do not contain completion scripts.
  completions_available = Gem::Version.new(version) > Gem::Version.new("0.5.2")
  if completions_available
    %w[svg-format svg-lint svg-language-server].each do |command|
      bash_completion "completions/bash/#{command}"
      zsh_completion "completions/zsh/_#{command}"
      fish_completion "completions/fish/#{command}.fish"
    end
    pwsh_completion "completions/powershell/_svg.ps1"
  end

  preflight_steps do
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}"]
    end
  end

  caveats <<~EOS if completions_available
    Load the PowerShell completions from your profile:
      . (Join-Path (brew --prefix) 'share/pwsh/completions/_svg.ps1')
  EOS

  zap :not_required
end
