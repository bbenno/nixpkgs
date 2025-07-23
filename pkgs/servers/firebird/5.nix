{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  termcap,
  libtool,
  libtommath,
  libedit,
  editline,
  icu,
  unzip,
  zlib,
  libtomcrypt,
  cmake,
  pkg-config,
  autoconf,
  automake,
  arch ? "classic"
}:

let
  archFlags = {
    "superserver" = [ "--enable-superserver" ];
    "superclassic" = [ ]; # build Classic, switch later
    "classic" = [ ];
  }."${arch}";
  inherit (lib) concatStringsSep;
in
stdenv.mkDerivation rec {
  pname = "firebird";
  version = "5.0.3";

  src = fetchFromGitHub {
    owner = "FirebirdSQL";
    repo = "firebird";
    rev = "v${version}";
    hash = "sha256-80GWjusRzQiNbUFsAbg/Cj9+/WW3KuJjMSA72EZVhN8=";
  };

  nativeBuildInputs = [
    autoreconfHook
    autoconf
    automake
    libtool
    pkg-config
    termcap
  ];

  buildInputs = [
    libtommath
    editline
    #libedit
    zlib.dev
    libtomcrypt
    icu
    cmake
  ];

  configureFlags = [
    "--with-system-editline"
    "--with-builtin-tommath"
  ]
  ++ archFlags;

  postInstall = ''
    if [ "${arch}" = "superclassic" ]; then
      # create wrapper for superclassic runtime mode
      ln -s $out/bin/fb_smp_server $out/bin/fb_superclassic
    fi
  '';

  meta = {
    description = "SQL relational database management system";
    downloadPage = "https://github.com/FirebirdSQL/firebird/";
    homepage = "https://firebirdsql.org/";
    changelog = "https://github.com/FirebirdSQL/firebird/blob/master/CHANGELOG.md";
    license = [
      "IDPL"
      "Interbase-1.0"
    ];
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ bbenno ];
  };
}
