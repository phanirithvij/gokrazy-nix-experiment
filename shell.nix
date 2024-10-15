let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  inherit (pkgs) lib;
  # IFD ftw! we are not nixpkgs
  # https://stackoverflow.com/a/66436501/8608146
  # pure nix alt https://github.com/oceanlewis/env-utils/blob/main/default.nix#L61
  env2json = pkgs.runCommand "env2json" { } ''
    cat ${./.env} | ${pkgs.jq}/bin/jq -nR '
    def parse: capture("(?<k>[^=]*)=(?<v>.*)");
    reduce inputs as $line ({};
       ($line | parse) as $p
       | .[$p.k] = ($p.v) )
    ' > $out
  '';
  env = builtins.fromJSON (builtins.readFile env2json);
  config = import ./config.nix env;
  gok' = pkgs.writeShellScriptBin "goke" ''
    GOARCH=amd64 ${lib.getExe pkgs.gokrazy} \
      -i gok --parent_dir gokrazy "$@"
  '';
  gok = lib.getExe gok';
in
pkgs.mkShellNoCC {
  shellHook =
    let
      a = "./gokrazy/${config.Hostname}";
    in
    ''
      mkdir -p ${a}
      cat <<'EOF' | jq > ${a}/config.json
      ${builtins.toJSON config}
      EOF
    '';
  packages = with pkgs; [
    go
    gok'
    gokrazy
    jq

    nixfmt-rfc-style
    npins
  ];
}
