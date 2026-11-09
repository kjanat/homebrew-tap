# frozen_string_literal: true

cask "envctl" do
  on_macos do
    on_arm do
      version "0.7.2"
      sha256 "c06193b2eba9c5fd2696a4e989376f45a9568176a95b86cbf1ee0acff3417e0b"
      url "https://github.com/kjanat/envctl/releases/download/v#{version}/envctl-darwin-arm64"
    end
    on_intel do
      version "0.7.2"
      sha256 "70aa44246d127de9da57d893c65a64e56c251eec7816891597cc742f449938e2"
      url "https://github.com/kjanat/envctl/releases/download/v#{version}/envctl-darwin-amd64"
    end
  end
  on_linux do
    on_arm do
      version "0.7.2"
      sha256 "e5c2c3774fb710a16ac437b113cd860f12c868f1d59089679f26248bd111ce13"
      url "https://github.com/kjanat/envctl/releases/download/v#{version}/envctl-linux-arm64"
    end
    on_intel do
      version "0.7.2"
      sha256 "e6d64fa8dd97c81dfc5f0fd732321abe45ac77b889bf9909c8c2eab8e6b848a0"
      url "https://github.com/kjanat/envctl/releases/download/v#{version}/envctl-linux-amd64"
    end
  end

  name "envctl"
  desc "Manage keys in env files"
  homepage "https://github.com/kjanat/envctl"

  livecheck do
    url :url
    strategy :github_latest
  end

  container type: :naked
  binary "envctl"
  manpage "envctl.1"
  artifact "envctl.psm1", target: "#{HOMEBREW_PREFIX}/share/powershell/Modules/envctl/envctl.psm1"
  generate_completions_from_executable "envctl", "completions",
                                       base_name: "envctl",
                                       shells:    [:bash, :zsh, :fish, :pwsh]

  # Releases contain only the binary; CI checks this manual against the release tag.
  manual = (Tap.fetch("kjanat/tap").path/"manpages/envctl/envctl.1").read
  preflight_steps do
    move "envctl-*", "envctl", source_glob: true
    set_permissions "envctl", "755", recursive: false
    write_file "envctl.1", manual
    mkdir_p "etc/bash_completion.d", base: :homebrew_prefix
    mkdir_p "share/zsh/site-functions", base: :homebrew_prefix
    mkdir_p "share/fish/vendor_completions.d", base: :homebrew_prefix
    mkdir_p "share/pwsh/completions", base: :homebrew_prefix
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}"]
    end
    run "{{staged_path}}/envctl", args: ["module", "pwsh"], stdout_path: "envctl.psm1"
  end

  caveats <<~EOS
    Load PowerShell completions from your profile:
      . (Join-Path (brew --prefix) 'share/pwsh/completions/_envctl.ps1')
    Load the generated PowerShell cmdlets with:
      Import-Module (Join-Path (brew --prefix) 'share/powershell/Modules/envctl/envctl.psm1')
  EOS

  zap :not_required
end
