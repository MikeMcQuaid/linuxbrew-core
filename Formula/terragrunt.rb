class Terragrunt < Formula
  desc "Thin wrapper for Terraform e.g. for locking state"
  homepage "https://github.com/gruntwork-io/terragrunt"
  url "https://github.com/gruntwork-io/terragrunt.git",
    :tag      => "v0.23.12",
    :revision => "9f8f3cb64f5135cc985f5509fbd8ec74fa4dba82"

  bottle do
    cellar :any_skip_relocation
    sha256 "b6e13496dcc8f3c9105bec16dd17071e2276c3967b02770e72c3ab1fde33289d" => :catalina
    sha256 "e651c7380055ba380deb1a2fc7f9b321192bb4c411f66c0da5d8a622afd0524a" => :mojave
    sha256 "c0e7622e5c65e03b4938db87b4a7024b8eac04c6a0886ca905bdaa92762f339e" => :high_sierra
    sha256 "46e5576374452a14d50dd414e10382a26bfb6267d1c7d55d1509428f331173be" => :x86_64_linux
  end

  depends_on "go" => :build
  depends_on "terraform"

  def install
    system "go", "build", "-ldflags", "-X main.VERSION=v#{version}", *std_go_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/terragrunt --version")
  end
end
