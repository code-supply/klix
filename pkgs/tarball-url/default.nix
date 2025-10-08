{ writeShellApplication }:

writeShellApplication {
  name = "klix-tarball-url";
  text = ''
    uuid=$1
    key_path=''${2:-/etc/ssh/ssh_host_ed25519_key}
    datetime="$(date --utc -Ins)"
    url_datetime="$(echo -n "$datetime" | base64)"
    url_signature="$(
      echo -n "$uuid$datetime" \
        | ssh-keygen -q -Y sign -n file -f "$key_path" \
        | base64 --wrap=0
    )"
    echo -n "https://klix.code.supply/images/$uuid/$url_datetime/$url_signature/config.tar.gz#default"
  '';
}
