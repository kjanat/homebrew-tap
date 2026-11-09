# frozen_string_literal: true

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
  desc "Static analysis tool for shell scripts, distributed as an upstream binary"
  homepage "https://www.shellcheck.net/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "shellcheck-v#{version}/shellcheck"
  bash_completion "shellcheck.bash", target: "shellcheck"
  zsh_completion "_shellcheck"
  fish_completion "shellcheck.fish"
  artifact "shellcheck.ps1",
           target: "#{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1"

  # Embed the files so serialized install steps do not depend on the tap path.
  preflight_steps({
    "bash/shellcheck"           => "shellcheck.bash",
    "fish/shellcheck.fish"      => "shellcheck.fish",
    "zsh/_shellcheck"           => "_shellcheck",
    "powershell/shellcheck.ps1" => "shellcheck.ps1",
  }.map do |source, target|
    {
      type:      "write",
      path:      { base: "staged_path", path: target },
      content:   (Tap.fetch("kjanat/tap").path/"completions/shellcheck"/source).read,
      overwrite: true,
    }
  end)

  caveats <<~EOS
    Homebrew installs completions for bash, zsh, and fish automatically.
    PowerShell completion is installed to
      #{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1
    Load it from your PowerShell profile:
      . (Join-Path (brew --prefix) 'share/powershell/completions/shellcheck.ps1')
  EOS
end
