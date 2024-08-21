class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "https://www.cs.utexas.edu/users/moore/acl2/manuals/current/manual/?topic=ACL2____ACL2-SEDAN"
  url "https://github.com/acl2/acl2/archive/236c425f6a679cb5bbc26627c1517ac506fd3b0a.tar.gz"
  version "0.1.12"
  sha256 "f3bf8f346070628c9f540a99478e5813dce021ad3f9b2ccfa769ff0cf6d41ec5"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/acl2s/homebrew-acl2s/releases/download/acl2s-0.1.12"
    sha256 arm64_ventura: "d748c00ba6e6edf0c839c75ccb085df8b9daad0735d07077b370e9cd167ae0a3"
    sha256 monterey:      "e6cabf3b00730f1a6e85286e0e8fa4133ba3052f2e10e22276fdabf8fc00ac11"
    sha256 x86_64_linux:  "cf182953f65f478a758620b704d51d3463b55dd49cea5ba2e202b5226bebc327"
  end

  depends_on "sbcl" => :build
  depends_on "zstd"

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.3.10/sbcl-2.3.10-source.tar.bz2"
    sha256 "358033315d07e4c5a6c838ee7f22cfc4d49e94848eb71ec1389d494bc32dd2ab"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/7b3c7332eb7563feeff589a4e927116132ff01c7/scripts-7b3c7332eb7563feeff589a4e927116132ff01c7.tar.gz"
    sha256 "baad56603a9cd295868db7bea01f675fd393adc67e0adb9f4ff948a13d2f46a0"
  end

  resource "calculational_proof_checker" do
    url "https://gitlab.com/acl2s/proof-checking/calculational-proof-checker/-/archive/ce0b753aa8c1e62edf54e1a2ff41c3f66e5f335e/calculational-proof-checker-ce0b753aa8c1e62edf54e1a2ff41c3f66e5f335e.tar.gz"
    sha256 "b7a81876941a1d6df1a4430fe5000c544b18b704c442df2e55da412f3e3888a6"
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
    rm_r sbcl_prefix if Dir.exist?(sbcl_prefix)
    mkdir_p sbcl_prefix
    resource("sbcl_files").stage do
      ENV["SBCL_MACOSX_VERSION_MIN"] = MacOS.version if OS.mac?
      xc_cmdline = "sbcl"
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
    rm_r scripts_prefix if Dir.exist?(scripts_prefix)
    rm_r acl2_prefix if Dir.exist?(acl2_prefix)
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
    rm_r quicklisp_prefix if Dir.exist?(quicklisp_prefix)
    buildpath.install resource("quicklisp_installer")
    system sbcl_prefix/"bin/sbcl", "--load", buildpath/"quicklisp.lisp", "--eval",
           "(quicklisp-quickstart:install :path \"#{quicklisp_prefix}\")", "--quit"
    rm buildpath/"quicklisp.lisp"

    # Install/build CPC
    rm_r cpc_prefix if Dir.exist?(cpc_prefix)
    mkdir_p cpc_prefix
    cpc_prefix.install resource("calculational_proof_checker")
    ENV["QUICKLISP_SETUP"] = quicklisp_prefix/"setup.lisp"
    cd cpc_prefix do
      system "make", "build-java-binary"
    end
    ln_sf cpc_prefix/"prove-file-java.sh", bin/"prove-file-java.sh"
  end

  test do
    (testpath/"simple.lisp").write "(+ 3 2)(quit)"
    output = shell_output("#{bin}/acl2s < #{testpath}/simple.lisp | grep 'ACL2S !>'")
    assert_equal "ACL2S !>5\nACL2S !>", output.strip
  end
end
