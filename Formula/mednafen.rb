class Mednafen < Formula
  desc "Multi-system emulator"
  homepage "https://mednafen.github.io/"
  url "https://mednafen.github.io/releases/files/mednafen-1.24.1.tar.xz"
  sha256 "a47adf3faf4da66920bebb9436e28cbf87ff66324d0bb392033cbb478b675fe7"

  bottle do
    sha256 "05d5e089426ad7855d7676b98cddd627bd4c0d9c1805612e3bcd7e9d4667c6c8" => :catalina
    sha256 "8f424aa04340125fe6b0556bc8554a145b43e4f7319b316f3179794628ccf40d" => :mojave
    sha256 "99b51ff663598acb7a178119a1510bf86f1d1002960f7b6c121911eec618650b" => :high_sierra
    sha256 "22aa99843864ac77a7ccfcfa65f80cc4a851f5c0d662ff3ca8c6954654f2c47c" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "libsndfile"
  depends_on :macos => :sierra # needs clock_gettime
  depends_on "sdl2"

  unless OS.mac?
    depends_on "zlib"
    depends_on "linuxbrew/xorg/glu"
    depends_on "linuxbrew/xorg/mesa"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    # Test fails on headless CI: Could not initialize SDL: No available video device
    return if ENV["CI"]

    cmd = "#{bin}/mednafen | head -n1 | grep -o '[0-9].*'"
    assert_equal version.to_s, shell_output(cmd).chomp
  end
end
