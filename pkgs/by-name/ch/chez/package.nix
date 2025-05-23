{
  lib,
  stdenv,
  llvmPackages_17,
  fetchurl,
  coreutils,
  cctools,
  darwin,
  ncurses,
  libiconv,
  libX11,
  libuuid,
  testers,
}@args:

let
  # x64 darwin fails with invalid memory reference with clang-18 & 19.
  # https://github.com/cisco/ChezScheme/issues/896
  # aarch64 darwin fails to execute `system` calls with clang-18 & 19.
  # https://github.com/cisco/ChezScheme/issues/928
  stdenv = if args.stdenv.hostPlatform.isDarwin then llvmPackages_17.stdenv else args.stdenv;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "chez-scheme";
  version = "10.2.0";

  src = fetchurl {
    url = "https://github.com/cisco/ChezScheme/releases/download/v${finalAttrs.version}/csv${finalAttrs.version}.tar.gz";
    hash = "sha256-t5WRbUz+1ZJAxfRLG1B6hlfv0o5i5y4TTQNIbp8+N0o=";
  };

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [
      cctools
    ]
    ++ lib.optionals (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) [
      darwin.autoSignDarwinBinariesHook
    ];
  buildInputs = [
    ncurses
    libiconv
    libX11
    libuuid
  ];

  enableParallelBuilding = true;

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.cc.isGNU "-Wno-error=format-truncation";

  /*
    ** We have to fix a few occurrences to tools with absolute
    ** paths in some helper scripts, otherwise the build will fail on
    ** NixOS or in any chroot build.
  */
  patchPhase = ''
    substituteInPlace ./makefiles/installsh \
      --replace-warn "/usr/bin/true" "${coreutils}/bin/true"

    substituteInPlace zlib/configure \
      --replace-warn "/usr/bin/libtool" libtool
  '';

  /*
    ** Don't use configureFlags, since that just implicitly appends
    ** everything onto a --prefix flag, which ./configure gets very angry
    ** about.
    **
    ** Also, carefully set a manual workarea argument, so that we
    ** can later easily find the machine type that we built Chez
    ** for.
  */
  configurePhase = ''
    ./configure --as-is --threads --installprefix=$out --installman=$out/share/man
  '';

  # ** Clean up some of the examples from the build output.
  postInstall = ''
    rm -rf $out/lib/csv${finalAttrs.version}/examples
  '';

  setupHook = ./setup-hook.sh;

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Powerful and incredibly fast R6RS Scheme compiler";
    homepage = "https://cisco.github.io/ChezScheme/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ thoughtpolice ];
    platforms = lib.platforms.unix;
    mainProgram = "scheme";
  };
})
