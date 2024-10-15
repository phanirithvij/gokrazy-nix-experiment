env:
let
  inherit (env) HTTPPassword TS_AUTHKEY;
  KernelPackage = "github.com/rtr7/kernel";
  tailscale = "tailscale.com/cmd/tailscale";
  golink = "github.com/tailscale/golink/cmd/golink";
  tclipd = "github.com/tailscale-dev/tclip/cmd/tclipd";
  tailpkgs = [
    tailscale
    "tailscale.com/cmd/tailscaled"
  ];
in
{
  Hostname = "gok";
  Update = {
    inherit HTTPPassword;
  };
  Packages =
    [
      "github.com/gokrazy/serial-busybox"
      "github.com/gokrazy/mkfs"
    ]
    ++ tailpkgs
    ++ [
      golink
      tclipd
    ];
  PackageConfig = {
    "github.com/gokrazy/gokrazy/cmd/randomd" = {
      ExtraFileContents = {
        "/etc/machine-id" = "fbbd84aa3e4b4b94b77c94213d6f9491\n";
      };
    };
    ${golink} = {
      Environment = [
        "TS_AUTHKEY=${TS_AUTHKEY}"
      ];
      CommandLineFlags = [
        "--sqlitedb=/perm/home/golink/data.db"
      ];
      WaitForClock = true;
    };
    ${tailscale} = {
      CommandLineFlags = [
        "up"
        "--authkey=${TS_AUTHKEY}"
      ];
    };
    ${tclipd} = {
      CommandLineFlags = [
        "--data-location=/perm/home/tclip/"
      ];
      WaitForClock = true;
      Environment = [
        "TS_AUTHKEY=${TS_AUTHKEY}"
      ];
    };
  };
  SerialConsole = "ttyS0,115200";
  inherit KernelPackage;
  FirmwarePackage = KernelPackage;
  InternalCompatibilityFlags = { };
}
