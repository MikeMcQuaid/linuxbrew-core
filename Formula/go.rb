class Go < Formula
  desc "The Go programming language"
  homepage "https://golang.org"

  stable do
    url "https://storage.googleapis.com/golang/go1.8.src.tar.gz"
    mirror "https://fossies.org/linux/misc/go1.8.src.tar.gz"
    version "1.8"
    sha256 "406865f587b44be7092f206d73fc1de252600b79b3cacc587b74b5ef5c623596"

    go_version = version.to_s.split(".")[0..1].join(".")
    resource "gotools" do
      url "https://go.googlesource.com/tools.git",
          :branch => "release-branch.go#{go_version}"
    end
  end

  bottle do
    sha256 "70f447e2d0a5214e533699ffa7ebadccd587919b288ee609ddb4e6ac84fc64e5" => :sierra
    sha256 "e593929c05df7894bebde4575c7e82238ca66b7a0ebf3286e2e74be39435f303" => :el_capitan
    sha256 "9bb46c195e6b2cd66d54cd0cac9823a69ec14eb0f02efa2fd8bfffcb6d19e0b4" => :yosemite
    sha256 "d63296701ec1983f34cba5eedd83e367186b5aee44ffba7625d12d29752248c8" => :x86_64_linux
  end

  head do
    url "https://go.googlesource.com/go.git"

    resource "gotools" do
      url "https://go.googlesource.com/tools.git"
    end
  end

  if OS.mac?
    option "without-cgo", "Build without cgo (also disables race detector)"
    option "without-race", "Build without race detector"
  end
  option "without-godoc", "godoc will not be installed for you"

  depends_on :macos => :mountain_lion

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    if OS.mac?
      url "https://storage.googleapis.com/golang/go1.7.darwin-amd64.tar.gz"
      sha256 "51d905e0b43b3d0ed41aaf23e19001ab4bc3f96c3ca134b48f7892485fc52961"
    elsif OS.linux?
      url "https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz"
      sha256 "702ad90f705365227e902b42d91dd1a40e48ca7f67a2f4b2fd052aaa4295cd95"
    end
    version "1.7"
  end

  def os
    OS.mac? ? "darwin" : "linux"
  end

  def install
    (buildpath/"gobootstrap").install resource("gobootstrap")
    ENV["GOROOT_BOOTSTRAP"] = buildpath/"gobootstrap"

    cd "src" do
      ENV["GOROOT_FINAL"] = libexec
      ENV["GOOS"]         = os

      # Fix error: unknown relocation type 42; compiled without -fpic?
      # See https://github.com/Linuxbrew/linuxbrew/issues/1057
      ENV["CGO_ENABLED"]  = "0" if build.without?("cgo") || OS.linux?
      system "./make.bash", "--no-clean"
    end

    (buildpath/"pkg/obj").rmtree
    rm_rf "gobootstrap" # Bootstrap not required beyond compile.
    libexec.install Dir["*"]
    bin.install_symlink Dir[libexec/"bin/go*"]

    # Race detector only supported on amd64 platforms.
    # https://golang.org/doc/articles/race_detector.html
    if build.with?("cgo") && build.with?("race") && MacOS.prefer_64_bit?
      system bin/"go", "install", "-race", "std"
    end

    if build.with? "godoc"
      ENV.prepend_path "PATH", bin
      ENV["GOPATH"] = buildpath
      (buildpath/"src/golang.org/x/tools").install resource("gotools")

      if build.with? "godoc"
        cd "src/golang.org/x/tools/cmd/godoc/" do
          system "go", "build"
          (libexec/"bin").install "godoc"
        end
        bin.install_symlink libexec/"bin/godoc"
      end
    end
  end

  def caveats; <<-EOS.undent
    As of go 1.2, a valid GOPATH is required to use the `go get` command.
    If $GOPATH is not specified, $HOME/go will be used by default:
      https://golang.org/doc/code.html#GOPATH

    You may wish to add the GOROOT-based install location to your PATH:
      export PATH=$PATH:#{opt_libexec}/bin
    EOS
  end

  test do
    (testpath/"hello.go").write <<-EOS.undent
    package main

    import "fmt"

    func main() {
        fmt.Println("Hello World")
    }
    EOS
    # Run go fmt check for no errors then run the program.
    # This is a a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    if build.with? "godoc"
      assert File.exist?(libexec/"bin/godoc")
      assert File.executable?(libexec/"bin/godoc")
    end

    if build.with? "cgo"
      ENV["GOOS"] = "freebsd"
      system bin/"go", "build", "hello.go"
    end
  end
end
