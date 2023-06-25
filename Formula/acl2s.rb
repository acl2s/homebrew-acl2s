class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "https://www.cs.utexas.edu/users/moore/acl2/manuals/current/manual/?topic=ACL2____ACL2-SEDAN"
  url "https://github.com/acl2/acl2/archive/a5aeae033f55517ac6ffa67945bb5d1be7da6e8d.tar.gz"
  version "0.1.7"
  sha256 "61fca3aa7f8cea136d92c7bc8f4aab52e21dbc75e54507d7cd1f7bddd402073d"
  license "BSD-3-Clause"

  depends_on "sbcl" => :build
  depends_on "zstd"

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.3.5/sbcl-2.3.5-source.tar.bz2"
    sha256 "89c90720cf9d05dbcd90d690e381a2514c0f1807159e0d7222220c5a8c2d5186"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/bba20c209af1351ea3ca4819f4001ff4db484792/scripts-bba20c209af1351ea3ca4819f4001ff4db484792.tar.gz"
    sha256 "2a59fd219335b37f24aa872af6b8ed9b3716856f62a211c491e8415a26c6e9b0"
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
      xc_cmdline = "#{HOMEBREW_PREFIX}/bin/sbcl"
      args = [
        "--xc-host=#{xc_cmdline}",
        "--prefix=#{sbcl_prefix}",
        "--without-immobile-space",
        "--without-immobile-code",
        "--without-compact-instance-header",
        "--with-sb-xref-for-internals",
        "--with-sb-after-xc-core",
        "--with-thread",
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
    ENV["ACL2"] = bin/"acl2"
    ENV["ACL2S_SCRIPTS"] = scripts_prefix
    ENV["ACL2_SYSTEM_BOOKS"] = acl2_prefix/"books"
    ENV["ACL2_LISP"] = sbcl_prefix/"bin/sbcl"
    ENV["ACL2S_NUM_JOBS"] = if ENV.key?("HOMEBREW_ACL2S_NUM_JOBS")
      ENV["HOMEBREW_ACL2S_NUM_JOBS"]
    else
      "4"
    end
    ENV["ACL2_SNAPSHOT_INFO"] = "CS2800 Fall 2023"
    ENV["CERT_PL_RM_OUTFILES"] = "1"
    cd base_prefix do
      system scripts_prefix/"clean-gen-acl2.sh", "--no-git", "--all"
      cd acl2_prefix/"books" do
        system "make", "build/Makefile-features"
      end
      system scripts_prefix/"gen-acl2s.sh", "--no-git"
    end
    ln_sf base_prefix/"acl2s", bin/"acl2s"
  end

  test do
    (testpath/"simple.lisp").write "(+ 3 2)(quit)"
    output = shell_output("#{bin}/acl2s < #{testpath}/simple.lisp | grep 'ACL2S !>'")
    assert_equal "ACL2S !>5\nACL2S !>", output.strip
  end
end
