class Acl2s < Formula
  desc "The ACL2 Sedan theorem prover, built on top of ACL2."
  homepage "http://acl2s.ccs.neu.edu"
  url "https://api.github.com/repos/acl2/acl2/zipball/b9b73e6b6d0fa76bbc76c9ea25e36e9b26f3d02d"
  version "0.1.4"
  sha256 "537986c4558922051d43e1f4e879ccc94a4b8a5be068d25854dfe3717708b232"
  license "BSD-3-Clause"
  depends_on "sbcl" => :build

  resource "sbcl_files" do
    url "http://prdownloads.sourceforge.net/sbcl/sbcl-2.1.11-source.tar.bz2?download"
    sha256 "bfc1481de7fdbdfaeef2ab0f0e8e84efd343433dea8d21cfbea8b0146cbdfefd"
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
    resource("sbcl_files").stage {
      if OS.mac?
        ENV["SBCL_MACOSX_VERSION_MIN"] = MacOS.version
      end
      args = [
        "--xc-host=#{HOMEBREW_PREFIX}/bin/sbcl",
        "--prefix=#{sbcl_prefix}",
        "--without-immobile-space",
        "--without-immobile-code",
        "--without-compact-instance-header",
        "--fancy",
        "--dynamic-space-size=4Gb"
      ]
      system "./make.sh", *args
      ENV["INSTALL_ROOT"] = sbcl_prefix
      system "sh", "install.sh"
    }

    # ACL2
    rm_rf scripts_prefix
    rm_rf acl2_prefix
    scripts_prefix.install resource("acl2s_scripts")
    acl2_prefix.install Dir['*']
    mkdir_p bin
    ENV.prepend_path "PATH", bin
    # For some reason Homebrew requires that the source
    # file exists when creating a symlink.
    # `ln` on my machine does not require this.
    touch "#{acl2_prefix}/saved_acl2"
    ln_sf acl2_prefix/"saved_acl2", bin/"acl2"
    ln_sf acl2_prefix/"books/build/cert.pl", bin/"cert.pl"
    ln_sf acl2_prefix/"books/build/clean.pl", bin/"clean.pl"
    ENV['ACL2S_SCRIPTS'] = scripts_prefix
    ENV['ACL2_SYSTEM_BOOKS'] = acl2_prefix/"books"
    ENV['ACL2_LISP'] = sbcl_prefix/"bin/sbcl"
    ENV['ACL2S_NUM_JOBS'] = "4"
    ENV['ACL2_SNAPSHOT_INFO'] = 'NONE'
    cd base_prefix do
      system scripts_prefix/"clean-gen-acl2-acl2s.sh", "--no-git"
    end
    ln_sf base_prefix/"acl2s", bin/"acl2s"
  end

  test do
    (testpath/"simple.lisp").write "(+ 2 2)(quit)"
    output = shell_output("#{bin}/acl2s < #{testpath}/simple.lisp | grep 'ACL2S !>'")
    assert_equal "ACL2S !>4\nACL2S !>", output.strip
  end
end
