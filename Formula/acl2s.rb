class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "http://acl2s.ccs.neu.edu"
  url "https://github.com/acl2/acl2/archive/877c0c24d44821875472c32e165557212b9a3f56.tar.gz"
  version "0.1.5"
  sha256 "2c7fc517e0c504b6b52399ba8bebeeb31020878dd1f9eb090578c491e2ef8a28"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/mister-walter/homebrew-acl2s/releases/download/acl2s-0.1.5"
    rebuild 1
    sha256 arm64_monterey: "36993989b59c80c675a60a6130d45bab5137caf308def3a08d383671437b0bc9"
    sha256 catalina:       "70f2a9578c79289fe3381f836a32572811d8f104e6ce9c8552171f254732696e"
    sha256 x86_64_linux:   "30a75d0404332584a0002e292fc260760702c35cc5cbf2dfa3eb5e4ed78b3058"
  end

  depends_on "sbcl" => :build
  depends_on "zlib" unless OS.mac?

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.2.0/sbcl-2.2.0-source.tar.bz2"
    sha256 "2276957ea86ae9968ca486a9928c67a34cb31c9403ec657d24ecdf8458daa5c6"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/ab2864f70484b1c855e0d287f10ff2eca855a36d/scripts-ab2864f70484b1c855e0d287f10ff2eca855a36d.tar.gz"
    sha256 "276d54dbfb027659d715531cd6b8a12e45e51731f30b00da2ccaa7ca34bc7e1c"
  end

  def install
    base_prefix = prefix/"opt/acl2s"
    sbcl_prefix = base_prefix/"sbcl"
    acl2_prefix = base_prefix/"acl2"
    scripts_prefix = base_prefix/"scripts"

    # SBCL install
    rm_rf sbcl_prefix
    mkdir_p sbcl_prefix
    resource("sbcl_files").stage do
      ENV["SBCL_MACOSX_VERSION_MIN"] = MacOS.version if OS.mac?
      args = [
        "--xc-host=#{HOMEBREW_PREFIX}/bin/sbcl",
        "--prefix=#{sbcl_prefix}",
        "--without-immobile-space",
        "--without-immobile-code",
        "--without-compact-instance-header",
        "--fancy",
        "--dynamic-space-size=4Gb",
      ]
      system "./make.sh", *args
      ENV["INSTALL_ROOT"] = sbcl_prefix
      system "sh", "install.sh"
    end

    # ACL2
    rm_rf scripts_prefix
    rm_rf acl2_prefix
    scripts_prefix.install resource("acl2s_scripts")
    acl2_prefix.install Dir["*"]
    mkdir_p bin
    ENV.prepend_path "PATH", bin
    # For some reason Homebrew requires that the source
    # file exists when creating a symlink.
    # `ln` on my machine does not require this.
    touch "#{acl2_prefix}/saved_acl2"
    ln_sf acl2_prefix/"saved_acl2", bin/"acl2"
    ln_sf acl2_prefix/"books/build/cert.pl", bin/"cert.pl"
    ln_sf acl2_prefix/"books/build/clean.pl", bin/"clean.pl"
    ENV["ACL2S_SCRIPTS"] = scripts_prefix
    ENV["ACL2_SYSTEM_BOOKS"] = acl2_prefix/"books"
    ENV["ACL2_LISP"] = sbcl_prefix/"bin/sbcl"
    ENV["ACL2S_NUM_JOBS"] = "4"
    ENV["ACL2_SNAPSHOT_INFO"] = "NONE"
    cd base_prefix do
      system scripts_prefix/"clean-gen-acl2-acl2s.sh", "--no-git"
    end
    ln_sf base_prefix/"acl2s", bin/"acl2s"
  end

  test do
    (testpath/"simple.lisp").write "(+ 3 2)(quit)"
    output = shell_output("#{bin}/acl2s < #{testpath}/simple.lisp | grep 'ACL2S !>'")
    assert_equal "ACL2S !>5\nACL2S !>", output.strip
  end
end
