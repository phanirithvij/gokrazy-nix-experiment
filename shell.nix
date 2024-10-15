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
  commands = [
    "${gok} new"
    "${gok} add $@"
    "${gok} update"
    "${gok} edit" # should edit template
    "pkill -3 qemu"
    ''
      qemu-system-x86_64 -machine accel=kvm \
       -smp 8 -m 2048 \
       -drive file=gokrazy.img,format=raw -nographic \
       -net nic \
       -net user,hostfwd=tcp::60080-:80
    ''
    "mkfs.ext4 -F -E offset=1157627904 ./gokrazy.img 3063791" # TODO auto extract offsets, how?
  ];
in
# TODO commands
# - menu
# - edit
# - upd
# - run
# - build
# - cheats
#
# - gh repo
# - nix-build -A image -> gokrazy.img (w/ mkfs.ext4 /perm enabled)
# - nix-build -A run-vm --check -> qemu (see microvm or sth for how to do it w/ simple qemu)
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
