class Lv < Formula
  desc "Powerful multi-lingual file viewer/grep"
  homepage "https://web.archive.org/web/20160310122517/www.ff.iij4u.or.jp/~nrt/lv/"
  url "https://web.archive.org/web/20150915000000/www.ff.iij4u.or.jp/~nrt/freeware/lv451.tar.gz"
  version "4.51"
  sha256 "e1cd2e27109fbdbc6d435f2c3a99c8a6ef2898941f5d2f7bacf0c1ad70158bcf"

  bottle do
    rebuild 1
    sha256 "055db6aed74a46e9676eb8c95a56a0402e1d18f3307d072ccecd04f6a9b9d916" => :catalina
    sha256 "6072b4788195dcb51fe2b9d08431ad22bd60eaaeae162c84bc9c2a7560bb7388" => :mojave
    sha256 "912eaa08af6da7ddba73f4169695073614641d67561f4e632e47960f0c07c6b3" => :high_sierra
    sha256 "01c44c5b3d18aa1602c00bc3ce8d0b71ae02cee6dfcff66d7e8df74b424b8de8" => :sierra
    sha256 "49ad4ebf6830c1ef3f6899486e711f99bc293d422317f8851f174cf18de2a98f" => :el_capitan
    sha256 "f31281558dc9da38402a86b2b3c03efb10ab471561bf72dd556c3cd8df23ba14" => :yosemite
    sha256 "6e1894088a741aba921e77a4935d6ad2d11f06f03a4ff775c45e4256728511a4" => :mavericks
    sha256 "2f1645287ed31f8ff3b947ad9a382c4325a07a70292c95d0f21b7468ba236121" => :x86_64_linux
  end

  depends_on "gzip" unless OS.mac?

  uses_from_macos "ncurses"

  def install
    # zcat doesn't handle gzip'd data on OSX.
    # Reported upstream to nrt@ff.iij4u.or.jp
    inreplace "src/stream.c", 'gz_filter = "zcat"', 'gz_filter = "gzcat"' if OS.mac?

    cd "build" do
      system "../src/configure", "--prefix=#{prefix}"
      system "make"
      bin.install "lv"
      bin.install_symlink "lv" => "lgrep"
    end

    man1.install "lv.1"
    (lib+"lv").install "lv.hlp"
  end
end
