# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  version "0.7.6"
  license "Apache-2.0"

  # libkrunfw versioned filenames (must match the build)
  LIBKRUNFW_VERSION = "5.6.1"
  LIBKRUNFW_ABI = "5"

  on_macos do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "a4f1722fee6460d4e2813e62b60dae4c092021d8120b7aaa9c2f4b5679d97d89"
    end

    on_intel do
      odie "microsandbox requires Apple Silicon (M1+). x86_64 macOS is not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "47e4787423b12f56f24119f657c54974b1869c0853b3d7a0873157668d29aa03"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "daa69c6a644289bbb7ef889bd862ffba7acddf934d45e724fa160edcd9a540e0"
    end
  end

  def install
    # Keep msb and its private libkrunfw together in libexec, then expose msb on
    # PATH through a wrapper script. The binary already carries an
    # @executable_path rpath, so it finds the library sitting beside it without
    # any install_name_tool edit. That matters on macOS: modifying the binary
    # would invalidate its code signature, and the release binary is signed with
    # the com.apple.security.hypervisor and disable-library-validation
    # entitlements it needs to boot VMs. Leaving the binary untouched preserves
    # the signature and those entitlements; a modified binary would be killed on
    # launch or lose the entitlements.
    libexec.install "msb"

    if OS.mac?
      # Tarball contains: libkrunfw.5.dylib
      libexec.install "libkrunfw.#{LIBKRUNFW_ABI}.dylib"
      libexec.install_symlink libexec/"libkrunfw.#{LIBKRUNFW_ABI}.dylib" => "libkrunfw.dylib"
    end

    if OS.linux?
      # Tarball contains: libkrunfw.so.5.2.1
      libexec.install "libkrunfw.so.#{LIBKRUNFW_VERSION}"
      libexec.install_symlink libexec/"libkrunfw.so.#{LIBKRUNFW_VERSION}" => "libkrunfw.so.#{LIBKRUNFW_ABI}"
      libexec.install_symlink libexec/"libkrunfw.so.#{LIBKRUNFW_VERSION}" => "libkrunfw.so"
    end

    bin.mkpath
    File.write(bin/"msb", <<~SH)
      #!/bin/bash
      exec "#{libexec}/msb" "$@"
    SH
    chmod 0755, bin/"msb"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/msb --version")
  end
end
