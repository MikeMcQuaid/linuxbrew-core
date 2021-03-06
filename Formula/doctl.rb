class Doctl < Formula
  desc "Command-line tool for DigitalOcean"
  homepage "https://github.com/digitalocean/doctl"
  url "https://github.com/digitalocean/doctl/archive/v1.43.0.tar.gz"
  sha256 "a55cc30b7e2ab37604eead742da6966c2c6715734a229263c6acae2092a932a0"
  head "https://github.com/digitalocean/doctl.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "c07547d09686eeaaefac0dca579704b346e389f7cebebe2a742eaae70b25070c" => :catalina
    sha256 "6a4dbb027badefc29ae8f79cca9aeb6a2ee62208ef187e2084982b9ff667f8b0" => :mojave
    sha256 "4b2f1ff61bc387125a9031664342926f8937c7159ce76ccf42f3fc7af7a5cad4" => :high_sierra
    sha256 "64bf03272b664ee515c8490bcb57873ee0efd319f8c524a1574fed301e1c64bc" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath

    doctl_version = version.to_s.split(/\./)

    src = buildpath/"src/github.com/digitalocean/doctl"
    src.install buildpath.children
    src.cd do
      base_flag = "-X github.com/digitalocean/doctl"
      ldflags = %W[
        #{base_flag}.Major=#{doctl_version[0]}
        #{base_flag}.Minor=#{doctl_version[1]}
        #{base_flag}.Patch=#{doctl_version[2]}
        #{base_flag}.Label=release
      ].join(" ")
      system "go", "build", "-ldflags", ldflags, "-o", bin/"doctl", "github.com/digitalocean/doctl/cmd/doctl"
    end

    (bash_completion/"doctl").write `#{bin}/doctl completion bash`
    (zsh_completion/"_doctl").write `#{bin}/doctl completion zsh`
    (fish_completion/"doctl.fish").write `#{bin}/doctl completion fish`
  end

  test do
    assert_match "doctl version #{version}-release", shell_output("#{bin}/doctl version")
  end
end
