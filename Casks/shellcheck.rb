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

  conflicts_with formula: "shellcheck"

  binary "shellcheck-v#{version}/shellcheck"
end
