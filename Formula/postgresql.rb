class Postgresql < Formula
  desc "Object-relational database system"
  homepage "https://www.postgresql.org/"
  url "https://ftp.postgresql.org/pub/source/v12.2/postgresql-12.2.tar.bz2"
  sha256 "ad1dcc4c4fc500786b745635a9e1eba950195ce20b8913f50345bb7d5369b5de"
  revision 1
  head "https://github.com/postgres/postgres.git"

  bottle do
    sha256 "ce2f6a9b19fae7a3baec603718b8817d0b67a2a0c017e85d8d6d97ada03e1962" => :catalina
    sha256 "9a546c991d33126374925630bf4f1487eed6a23f55e5fd5a8c907a7d9a60bb77" => :mojave
    sha256 "e1877be7ea8ef5d7cdbb9d5b0d4d378e800882d7ccbe35f1be63979f3fcfa963" => :high_sierra
    sha256 "43fa81d1061272eae422e89c706296be40e947e1f5bca0a034209d1b44a56802" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "icu4c"
  # GSSAPI provided by Kerberos.framework crashes when forked.
  # See https://github.com/Homebrew/homebrew-core/issues/47494.
  depends_on "krb5"
  depends_on "openssl@1.1"
  depends_on "readline"
  depends_on "util-linux" unless OS.mac?

  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "perl"

  def install
    # avoid adding the SDK library directory to the linker search path
    ENV["XML2_CONFIG"] = "xml2-config --exec-prefix=/usr"

    ENV.prepend "LDFLAGS", "-L#{Formula["openssl@1.1"].opt_lib} -L#{Formula["readline"].opt_lib}"
    ENV.prepend "CPPFLAGS", "-I#{Formula["openssl@1.1"].opt_include} -I#{Formula["readline"].opt_include}"

    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --datadir=#{HOMEBREW_PREFIX}/share/postgresql
      --libdir=#{HOMEBREW_PREFIX}/lib
      --includedir=#{HOMEBREW_PREFIX}/include
      --sysconfdir=#{etc}
      --docdir=#{doc}
      --enable-thread-safety
      --with-icu
      --with-libxml
      --with-libxslt
      --with-openssl
      --with-perl
      --with-uuid=e2fs
    ]
    if OS.mac?
      args += %w[
        --with-bonjour
        --with-gssapi
        --with-ldap
        --with-pam
      ]
    end

    # The CLT is required to build Tcl support on 10.7 and 10.8 because
    # tclConfig.sh is not part of the SDK
    if OS.mac?
      args << "--with-tcl"
      if File.exist?("#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework/tclConfig.sh")
        args << "--with-tclconfig=#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework"
      end
    end

    system "./configure", *args
    system "make"
    system "make", "install-world", "datadir=#{pkgshare}",
                                    "libdir=#{lib}",
                                    "pkglibdir=#{lib}/postgresql",
                                    "includedir=#{include}",
                                    "pkgincludedir=#{include}/postgresql",
                                    "includedir_server=#{include}/postgresql/server",
                                    "includedir_internal=#{include}/postgresql/internal"

    unless OS.mac?
      inreplace lib/"postgresql/pgxs/src/Makefile.global",
                "LD = #{HOMEBREW_PREFIX}/Homebrew/Library/Homebrew/shims/linux/super/ld",
                "LD = #{HOMEBREW_PREFIX}/bin/ld"
    end
  end

  def post_install
    return if ENV["CI"]

    (var/"log").mkpath
    (var/"postgres").mkpath
    if !Process.euid.zero? && !(File.exist? "#{var}/postgres/PG_VERSION")
      system "#{bin}/initdb", "--locale=C", "-E", "UTF-8", "#{var}/postgres"
    end
  end

  def caveats
    <<~EOS
      To migrate existing data from a previous major version of PostgreSQL run:
        brew postgresql-upgrade-database
    EOS
  end

  plist_options :manual => "pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres start"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/postgres</string>
          <string>-D</string>
          <string>#{var}/postgres</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/postgres.log</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/postgres.log</string>
      </dict>
      </plist>
    EOS
  end

  test do
    system "#{bin}/initdb", testpath/"test" unless ENV["CI"]
    assert_equal "#{HOMEBREW_PREFIX}/share/postgresql", shell_output("#{bin}/pg_config --sharedir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/lib", shell_output("#{bin}/pg_config --libdir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/lib/postgresql", shell_output("#{bin}/pg_config --pkglibdir").chomp
  end
end
