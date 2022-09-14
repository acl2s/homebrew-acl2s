class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "http://acl2s.ccs.neu.edu"
  url "https://github.com/acl2/acl2/archive/2ea4ded522b0aded4882a473800df4b5730f2239.tar.gz"
  version "0.1.6"
  sha256 "568c151429d4fbe8a998d60c90ce13b7e36ca0f0f92c08c0fd035894580029ae"
  license "BSD-3-Clause"

  depends_on "sbcl" => :build
  depends_on "zstd"

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.2.8/sbcl-2.2.8-source.tar.bz2"
    sha256 "992fcc2b5319010f7587cdc2294b088a595d6c0982ff195b565adfaf4b7d7b0e"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/100a982a5cf1a276ae6c5db4d608bd37edb3c6f2/scripts-100a982a5cf1a276ae6c5db4d608bd37edb3c6f2.tar.gz"
    sha256 "02103ba5044c54bc850b9a5c0394a536f1e86b8cbf6196aeaf8331cef97127d5"
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
    ENV["ACL2"] = bin/"acl2"
    ENV["ACL2S_SCRIPTS"] = scripts_prefix
    ENV["ACL2_SYSTEM_BOOKS"] = acl2_prefix/"books"
    ENV["ACL2_LISP"] = sbcl_prefix/"bin/sbcl"
    ENV["ACL2S_NUM_JOBS"] = "4"
    ENV["ACL2_SNAPSHOT_INFO"] = "CS2800 Fall 2022"
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
