{pkgs}:
pkgs.mkYarnPackage rec {
  pname = "ddb-proxy";
  version = "0.0.25";

  src = pkgs.fetchFromGitHub {
    owner = "MrPrimate";
    repo = "ddb-proxy";
    rev = "v${version}";
    sha256 = "sha256-RZzdT32jJA3cnVHkZ4Z4M1l0PFwc/4u3/BpaE3u9kh0=";
  };

  packageJson = "${src}/package.json";
  yarnLock = "${src}/yarn.lock";

  buildPhase = ''
    echo "Building ddb-proxy..."
  '';

  distPhase = "true";

  nativeBuildInputs = [pkgs.makeWrapper];

  postInstall = ''
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/ddb-proxy \
      --add-flags "$out/libexec/ddb-proxy/deps/ddb-proxy/index.js"
  '';
}
