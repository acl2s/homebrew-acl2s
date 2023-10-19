class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "https://www.cs.utexas.edu/users/moore/acl2/manuals/current/manual/?topic=ACL2____ACL2-SEDAN"
  url "https://github.com/acl2/acl2/archive/a718c3aab01cc2980978136356ca5f9474ea5c94.tar.gz"
  version "0.1.10"
  sha256 "d9b3688680b9c427ab9a36f8aa2c8deac06914b15af8991d215b4234fe8e1457"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/mister-walter/homebrew-acl2s/releases/download/acl2s-0.1.10"
    sha256 arm64_sonoma:  "5591010b15167de429f9838a123f50af287134141ed0708d855fa32287558f48"
    sha256 arm64_ventura: "881c414003e7aac54a34094d233a93a61024d9bfde327a77d364f6333b8538ff"
    sha256 monterey:      "a642790b6599b0dc45f3e57c951f8ea3234b08a8face8aae3730140c5ee0e8b0"
    sha256 big_sur:       "17b381eb32015ef7d0717256c532fba233991d3104985b892ac132bb109fc4bc"
    sha256 x86_64_linux:  "1921953bb6d26e5791210462529a8276284391d68e2c93d1b58cd38ecd65f318"
  end

  depends_on "sbcl" => :build
  depends_on "zstd"

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.3.9/sbcl-2.3.9-source.tar.bz2"
    sha256 "7d289a91232022028bf0128900c32bf00e4c5430c32f28af0594c8a592a98654"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/7b3c7332eb7563feeff589a4e927116132ff01c7/scripts-7b3c7332eb7563feeff589a4e927116132ff01c7.tar.gz"
    sha256 "baad56603a9cd295868db7bea01f675fd393adc67e0adb9f4ff948a13d2f46a0"
  end

  resource "calculational_proof_checker" do
    url "https://gitlab.com/acl2s/proof-checking/calculational-proof-checker/-/archive/f99378b3968e23dab12976dd6159a483cf8abe19/calculational-proof-checker-f99378b3968e23dab12976dd6159a483cf8abe19.tar.gz"
    sha256 "ac881f3000843c7e8a722b4f059db30c02799313829af8184c89390286d326a3"
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
