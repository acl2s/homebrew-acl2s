class Acl2s < Formula
  desc "ACL2 Sedan theorem prover, built on top of ACL2"
  homepage "https://www.cs.utexas.edu/users/moore/acl2/manuals/current/manual/?topic=ACL2____ACL2-SEDAN"
  url "https://github.com/acl2/acl2/archive/1a6eb5cd12d6ed4982e2a5ba9614169ce74af0da.tar.gz"
  version "0.1.13"
  sha256 "6851c18747fbb8dff82518d4f80a04c1f6b9007cd51ecda9c2368810caa1c8fc"
  license "BSD-3-Clause"

  depends_on "sbcl" => :build
  depends_on "zstd"

  resource "sbcl_files" do
    url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.4.7/sbcl-2.4.7-source.tar.bz2"
    sha256 "68544d2503635acd015d534ccc9b2ae9f68996d429b5a9063fd22ff0925011d2"
  end

  resource "acl2s_scripts" do
    url "https://gitlab.com/acl2s/external-tool-support/scripts/-/archive/a1cdbf02f0d2fa371b531b0d9a00ee4d534e4572/scripts-a1cdbf02f0d2fa371b531b0d9a00ee4d534e4572.tar.gz"
    sha256 "734daa675e384e79b314c1bbcecba915a9036d069cf50e9e265f54f4b12fc97b"
  end

  resource "calculational_proof_checker" do
    url "https://gitlab.com/acl2s/proof-checking/calculational-proof-checker/-/archive/1408c232c486ea6334f59af632eceac9a67b7fec/calculational-proof-checker-1408c232c486ea6334f59af632eceac9a67b7fec.tar.gz"
    sha256 "e34522ce4b337cf8582ccd393419ee785134899e915c9de6cb9d9bc69c31e9ca"
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
    ENV["ACL2_SNAPSHOT_INFO"] = "CS2800 Fall 2024"
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
