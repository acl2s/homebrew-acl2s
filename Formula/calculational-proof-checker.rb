class CalculationalProofChecker < Formula
  desc "Checker for calculational proofs"
  homepage "https://gitlab.com/acl2s/proof-checking/calculational-proof-checker"
  url "https://gitlab.com/acl2s/proof-checking/calculational-proof-checker/-/archive/470b3642903801fc6e18d0ca3ae633d1d117decc/calculational-proof-checker-470b3642903801fc6e18d0ca3ae633d1d117decc.tar.gz"
  version "0.0.1"
  sha256 "b5b1be2ef7ee56db9aefc4665db001c92848f805ff86adbfea3517088dddf10d"
  depends_on "acl2s"

  resource "quicklisp_installer" do
    url "https://beta.quicklisp.org/quicklisp.lisp"
    sha256 "4a7a5c2aebe0716417047854267397e24a44d0cce096127411e9ce9ccfeb2c17"
  end

  def install
    base_prefix = prefix/"opt/cpc"
    quicklisp_prefix = base_prefix/"quicklisp"
    cpc_prefix = base_prefix/"calculational-proof-checker"
    sbcl_bin = Formula["acl2s"].opt_prefix/"opt/acl2s/sbcl/bin/sbcl"
    acl2s_bin = Formula["acl2s"].bin/"acl2s"

    # Install quicklisp
    rm_rf quicklisp_prefix
    buildpath.install resource("quicklisp_installer")
    system sbcl_bin, "--load", buildpath/"quicklisp.lisp", "--eval",
           "(quicklisp-quickstart:install :path \"#{quicklisp_prefix}\")", "--quit"
    rm buildpath/"quicklisp.lisp"

    # Install/build CPC
    rm_rf cpc_prefix
    mkdir_p cpc_prefix
    cpc_prefix.install Dir["*"]
    ENV["ACL2S_EXE"] = acl2s_bin
    ENV["ACL2_SYSTEM_BOOKS"] = Formula["acl2s"].opt_prefix/"opt/acl2s/acl2/books"
    ENV["QUICKLISP_SETUP"] = quicklisp_prefix/"setup.lisp"
    ENV["ACL2S_NUM_JOBS"] = "2"
    cd cpc_prefix do
      system "make", "prove-file-java"
    end
    mkdir_p bin
    ln_sf cpc_prefix/"prove-file-java.sh", bin/"prove-file-java.sh"
  end

  test do
    # TODO: add a real test
    assert_equal "t", "t"
  end
end
