# frozen_string_literal: true

cask "runner" do
  on_macos do
    on_arm do
      version "0.28.0"
      sha256 "5f62540fc9b68df501a4897798faa054cb71f9ecdbb20cb375f54638a30874f6"
      url "https://github.com/kjanat/runner/releases/download/v#{version}/runner-v#{version}-aarch64-apple-darwin.tar.gz"
    end
    on_intel do
      version "0.28.0"
      sha256 "baaae754462d2967d9ffbbca08f42bd8b8b240d21e9dc1ba3a1e34aa9e23f9ff"
      url "https://github.com/kjanat/runner/releases/download/v#{version}/runner-v#{version}-x86_64-apple-darwin.tar.gz"
    end
  end
  on_linux do
    on_arm do
      version "0.28.0"
      sha256 "ac6eb20a24c0819997a8a712a76f122f9d24d2ac0c6bbefbca44ec6f0789f2d2"
      url "https://github.com/kjanat/runner/releases/download/v#{version}/runner-v#{version}-aarch64-unknown-linux-musl.tar.gz"
    end
    on_intel do
      version "0.28.0"
      sha256 "3af3d984f07bd0ca6d1210e23ca67fece6d7ccd6c8a803a695278668a1103a05"
      url "https://github.com/kjanat/runner/releases/download/v#{version}/runner-v#{version}-x86_64-unknown-linux-musl.tar.gz"
    end
  end

  name "runner"
  desc "Universal project task runner"
  homepage "https://runner.kjanat.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "runner"
  binary "run"
  generate_completions_from_executable "runner", "completions",
                                       base_name: "runner",
                                       shells:    [:bash, :zsh, :fish, :pwsh]

  preflight_steps do
    mkdir_p "etc/bash_completion.d", base: :homebrew_prefix
    mkdir_p "share/zsh/site-functions", base: :homebrew_prefix
    mkdir_p "share/fish/vendor_completions.d", base: :homebrew_prefix
    mkdir_p "share/pwsh/completions", base: :homebrew_prefix
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}"]
    end
  end

  zap :not_required
end
