# frozen_string_literal: true

cask "fsql" do
  on_macos do
    on_arm do
      version "0.3.0"
      sha256 "1111111111111111111111111111111111111111111111111111111111111111"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-aarch64-apple-darwin"
    end
    on_intel do
      version "0.3.0"
      sha256 "2222222222222222222222222222222222222222222222222222222222222222"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-x86_64-apple-darwin"
    end
  end
  on_linux do
    on_arm do
      version "0.3.0"
      sha256 "3333333333333333333333333333333333333333333333333333333333333333"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-aarch64-unknown-linux-gnu"
    end
    on_intel do
      version "0.3.0"
      sha256 "4444444444444444444444444444444444444444444444444444444444444444"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-x86_64-unknown-linux-gnu"
    end
    caveats "The Linux release requires glibc 2.34 or newer."
  end

  name "fsql"
  desc "Query and modify the filesystem with SQL"
  homepage "https://github.com/kjanat/fsql"

  livecheck do
    url :url
    strategy :github_latest
  end

  container type: :naked
  binary "fsql"

  preflight_steps do
    move "fsql-*", "fsql", source_glob: true
    set_permissions "fsql", "755", recursive: false
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}"]
    end
  end
end
