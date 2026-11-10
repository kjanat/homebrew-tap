# frozen_string_literal: true

cask "fsql" do
  on_macos do
    on_arm do
      version "0.2.0"
      sha256 "819081e73f2aa4d940eebde5fe8d3738c6dfea060ac21934c927450e43ae9144"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-aarch64-apple-darwin"
    end
    on_intel do
      version "0.2.0"
      sha256 "59f45fb9af9ff8328636e6b622c1d61378e00f04705449a4213db3824afa186a"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-x86_64-apple-darwin"
    end
  end
  on_linux do
    on_arm do
      version "0.2.0"
      sha256 "e91278ebc68b27fc13d9867bd624dba2df13aa01ba54cbde0457580b28df0707"
      url "https://github.com/kjanat/fsql/releases/download/v#{version}/fsql-aarch64-unknown-linux-gnu"
    end
    on_intel do
      version "0.2.0"
      sha256 "150e0ff9c2ba6025b44f7fff91b23ef62d75b49d702fb43f39429990f8f20d2d"
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
