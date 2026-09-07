cask "shellcheck" do
  version "0.11.0"

  on_macos do
    on_arm do
      sha256 "56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.darwin.aarch64.tar.xz"
    end
    on_intel do
      sha256 "3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.darwin.x86_64.tar.xz"
    end
  end
  on_linux do
    on_arm do
      sha256 "12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.linux.aarch64.tar.xz"
    end
    on_intel do
      sha256 "8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.linux.x86_64.tar.xz"
    end
  end

  name "ShellCheck"
  desc "Static analysis tool for shell scripts, as the static binary the project releases"
  homepage "https://www.shellcheck.net/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "shellcheck-v#{version}/shellcheck"
  bash_completion "shellcheck.bash", target: "shellcheck"
  fish_completion "shellcheck.fish"
  zsh_completion "_shellcheck"
  artifact "shellcheck.ps1",
           target: "#{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1"

  preflight do
    completions = cask.tap.path/"completions/shellcheck"
    FileUtils.cp completions/"bash/shellcheck", staged_path/"shellcheck.bash"
    FileUtils.cp completions/"fish/shellcheck.fish", staged_path/"shellcheck.fish"
    FileUtils.cp completions/"zsh/_shellcheck", staged_path/"_shellcheck"
    FileUtils.cp completions/"powershell/shellcheck.ps1", staged_path/"shellcheck.ps1"
  end

  caveats <<~EOS
    PowerShell completion is installed to
      #{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1
    Load it from your PowerShell profile:
      . (Join-Path (brew --prefix) 'share/powershell/completions/shellcheck.ps1')
  EOS
end
