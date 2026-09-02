{
  lib,
  coreutils,
  jq,
  runCommand,
  writeShellApplication,
  writeText,
  redirectsFile,
}:
{
  base ? ../.,
  head ? ../.,
}:
let
  check = writeShellApplication {
    name = "check-redirects";
    runtimeInputs = [
      coreutils
      jq
    ];
    text =
      let
        help = writeText "redirects-check-help" ''
          Please don't remove old URLs, since this will break links and bookmarks.
          Redirect them to a different anchor, such as a release note mentioning the removal.

          To avoid manual book keeping, inside `nix-shell ${builtins.dirOf redirectsFile}` run:
            redirects remove-and-redirect <old-id> <target-id>
        '';
      in
      ''
        removed=$(comm -23 \
          <(jq -r '.[][]' "$1/${redirectsFile}" | sort) \
          <(jq -r '.[][]' "$2/${redirectsFile}" | sort))
        if [ -n "$removed" ]; then
          cat ${help}
          echo
          echo "URLs removed from ${redirectsFile}:"
          while IFS= read -r url; do echo "  $url"; done <<< "$removed"
          exit 1
        fi
      '';
  };
in
runCommand "redirects-check" { } ''
  ${lib.getExe check} ${base} ${head}
  touch $out
''
