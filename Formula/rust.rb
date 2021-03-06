class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"

  stable do
    url "https://static.rust-lang.org/dist/rustc-1.43.0-src.tar.gz"
    sha256 "75f6ac6c9da9f897f4634d5a07be4084692f7ccc2d2bb89337be86cfc18453a1"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git",
          :tag      => "0.44.0",
          :revision => "3532cf738db005a56d1fe81ade514f380d411360"
    end
  end

  bottle do
    sha256 "5b24bc9e45f31e9d9db268207ae198bba0393c1beaef994003bae0ea0d400a93" => :catalina
    sha256 "ff7e3a351573fd4528cc49d3ed18e2011957e9a076250620877e718fc2a38247" => :mojave
    sha256 "dd233197b81c522f5f2b475cb4f91b4dc9671b7532f092286469a6d77578228c" => :high_sierra
    sha256 "9636cb7454ea90a80874f1c88f12aa5222859bba1c6a0541dc2f8553110bd477" => :x86_64_linux
  end

  head do
    url "https://github.com/rust-lang/rust.git"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git"
    end
  end

  depends_on "cmake" => :build
  depends_on "python@3.8" => :build
  depends_on "libssh2"
  depends_on "openssl@1.1"
  depends_on "pkg-config"

  depends_on "binutils" unless OS.mac?

  uses_from_macos "curl"
  uses_from_macos "zlib"

  resource "cargobootstrap" do
    if OS.mac?
      # From https://github.com/rust-lang/rust/blob/#{version}/src/stage0.txt
      url "https://static.rust-lang.org/dist/2020-03-12/cargo-0.43.0-x86_64-apple-darwin.tar.gz"
      sha256 "92d4c9fb4747dce158cdfb773651aea8eac894277f3a2de5aa2c3b9d92439d8e"
    elsif OS.linux?
      # From: https://github.com/rust-lang/rust/blob/#{version}/src/stage0.txt
      url "https://static.rust-lang.org/dist/2020-03-12/cargo-0.43.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "97dde85ea43ccff8202fb77c4d1a5987c3332e578b852b82b426ecff2fa5a9a2"
    end
  end

  def install
    ENV.prepend_path "PATH", Formula["python@3.8"].opt_libexec/"bin"

    # Fix build failure for compiler_builtins "error: invalid deployment target
    # for -stdlib=libc++ (requires OS X 10.7 or later)"
    ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version if OS.mac?

    # Ensure that the `openssl` crate picks up the intended library.
    # https://crates.io/crates/openssl#manual-configuration
    ENV["OPENSSL_DIR"] = Formula["openssl@1.1"].opt_prefix

    # Fix build failure for cmake v0.1.24 "error: internal compiler error:
    # src/librustc/ty/subst.rs:127: impossible case reached" on 10.11, and for
    # libgit2-sys-0.6.12 "fatal error: 'os/availability.h' file not found
    # #include <os/availability.h>" on 10.11 and "SecTrust.h:170:67: error:
    # expected ';' after top level declarator" among other errors on 10.12
    ENV["SDKROOT"] = MacOS.sdk_path if OS.mac?

    args = ["--prefix=#{prefix}"]
    if build.head?
      args << "--disable-rpath"
      args << "--release-channel=nightly"
    else
      args << "--release-channel=stable"
    end
    system "./configure", *args
    system "make"
    system "make", "install"

    resource("cargobootstrap").stage do
      system "./install.sh", "--prefix=#{buildpath}/cargobootstrap"
    end
    ENV.prepend_path "PATH", buildpath/"cargobootstrap/bin"

    resource("cargo").stage do
      ENV["RUSTC"] = bin/"rustc"
      args = %W[--root #{prefix} --path . --features curl-sys/force-system-lib-on-osx]
      args -= %w[--features curl-sys/force-system-lib-on-osx] unless OS.mac?
      system "cargo", "install", *args
    end

    rm_rf prefix/"lib/rustlib/uninstall.sh"
    rm_rf prefix/"lib/rustlib/install.log"
  end

  def post_install
    Dir["#{lib}/rustlib/**/*.dylib"].each do |dylib|
      chmod 0664, dylib
      MachO::Tools.change_dylib_id(dylib, "@rpath/#{File.basename(dylib)}")
      chmod 0444, dylib
    end
  end

  test do
    system "#{bin}/rustdoc", "-h"
    (testpath/"hello.rs").write <<~EOS
      fn main() {
        println!("Hello World!");
      }
    EOS
    system "#{bin}/rustc", "hello.rs"
    assert_equal "Hello World!\n", `./hello`
    system "#{bin}/cargo", "new", "hello_world", "--bin"
    assert_equal "Hello, world!",
                 (testpath/"hello_world").cd { `#{bin}/cargo run`.split("\n").last }
  end
end
