class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "https://www.cs.utexas.edu/users/moore/acl2/manuals/current/manual/?topic=ACL2____ACL2-SEDAN"
  url "https://github.com/acl2/acl2/archive/a718c3aab01cc2980978136356ca5f9474ea5c94.tar.gz"
  version "0.1.8"
  sha256 "d9b3688680b9c427ab9a36f8aa2c8deac06914b15af8991d215b4234fe8e1457"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/mister-walter/homebrew-acl2s/releases/download/acl2s-0.1.8"
    sha256 big_sur:      "fbe0c9a1c535f7914c1adb32df9a0811b877ac93a80147ff4de51493d8532fee"
    sha256 x86_64_linux: "96b70e00111ad7a1f814f4441fae7e169a121ecae4febc02f0f85a8f2a7ef3b8"
  end

  depends_on "sbcl" => :build
  depends_on "zstd"

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.3.6/sbcl-2.3.6-source.tar.bz2"
    sha256 "b4414ca4d9a7474e8d884d7d63237e2f29ef459dfd5a848424a9c3fa551d19b9"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/7b3c7332eb7563feeff589a4e927116132ff01c7/scripts-7b3c7332eb7563feeff589a4e927116132ff01c7.tar.gz"
    sha256 "baad56603a9cd295868db7bea01f675fd393adc67e0adb9f4ff948a13d2f46a0"
  end

  resource "calculational_proof_checker" do
    url "https://gitlab.com/acl2s/proof-checking/calculational-proof-checker/-/archive/470b3642903801fc6e18d0ca3ae633d1d117decc/calculational-proof-checker-470b3642903801fc6e18d0ca3ae633d1d117decc.tar.gz"
    sha256 "b5b1be2ef7ee56db9aefc4665db001c92848f805ff86adbfea3517088dddf10d"
  end

  resource "quicklisp_installer" do
    url "https://beta.quicklisp.org/quicklisp.lisp"
    sha256 "4a7a5c2aebe0716417047854267397e24a44d0cce096127411e9ce9ccfeb2c17"
  end

  def install
    base_prefix = prefix/"opt/acl2s"
    sbcl_prefix = base_prefix/"sbcl"
    acl2_prefix = base_prefix/"acl2"
    quicklisp_prefix = base_prefix/"quicklisp"
    cpc_prefix = base_prefix/"calculational-proof-checker"
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
      system scripts_prefix/"clean-gen-acl2-acl2s.sh", "--no-git", "--all"
    end
    ln_sf base_prefix/"acl2s", bin/"acl2s"

    # Install Quicklisp
    rm_rf quicklisp_prefix
    buildpath.install resource("quicklisp_installer")
    system sbcl_prefix/"bin/sbcl", "--load", buildpath/"quicklisp.lisp", "--eval",
           "(quicklisp-quickstart:install :path \"#{quicklisp_prefix}\")", "--quit"
    rm buildpath/"quicklisp.lisp"

    # Install/build CPC
    rm_rf cpc_prefix
    mkdir_p cpc_prefix
    cpc_prefix.install resource("calculational_proof_checker")
    ENV["QUICKLISP_SETUP"] = quicklisp_prefix/"setup.lisp"
    cd cpc_prefix do
      system "make", "prove-file-java"
    end
    ln_sf cpc_prefix/"prove-file-java.sh", bin/"prove-file-java.sh"
  end

  test do
    (testpath/"simple.lisp").write "(+ 3 2)(quit)"
    output = shell_output("#{bin}/acl2s < #{testpath}/simple.lisp | grep 'ACL2S !>'")
    assert_equal "ACL2S !>5\nACL2S !>", output.strip
  end
end
