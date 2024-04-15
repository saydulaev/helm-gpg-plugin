#!/bin/bash

set -eu


usage() {
cat << EOF
GnuPG integration with Helm

This provides integration with 'gpg', the command line tool for working with
GnuPG.

Available Commands:
  sign    Sign a chart archive (tgz file) with a GPG key
  verify  Verify a chart archive (tgz + tgz.prov) with your GPG keyring

EOF
}

sign_usage() {
cat << EOF
Sign a chart using GnuPG credentials.

This is an alternative to 'helm sign'. It uses your gpg credentials
to sign a chart.

Example:
    $ helm gpg sign foo-1.4.4.tgz
    # With additional params key name, passphrase, keystore
    $ helm gpg sign foo-1.4.4.tgz -u KEYNAME --passphrase SECRETPASSPHRASE --keyring ~/.gnupg/KEYRINGNAME

EOF
}

verify_usage() {
cat << EOF
Verify a chart

This is an alternative to 'helm verify'. It uses your gpg credentials
to verify a chart.

Example:
    $ helm gpg verify foo-1.4.4.tgz
    # With additional params
    $ helm gpg verify foo-1.4.4.tgz -u KEYNAME --keyring ~/.gnupg/KEYRINGNAME

In typical usage, use 'helm fetch --prov' to fetch a chart:

    $ helm fetch --prov upstream/wordpress
    $ helm gpg verify wordpress-1.2.3.tgz
    $ helm install ./wordpress-1.2.3.tgz

EOF
}

is_help() {
  case "$1" in
  "-h")
    return 0
    ;;
  "--help")
    return 0
    ;;
  "help")
    return 0
    ;;
  *)
    return 1
    ;;
esac
}


sign() {
  if is_help $1 ; then
    sign_usage
    return
  fi
  chart=$1
  shift
  echo "Signing $chart"
  shasum=$(openssl dgst -sha512 $chart| awk '{ print $2 }')
  chartyaml=$(tar -zxf $chart --exclude 'charts/' -O '*/Chart.yaml')
c=$(cat << EOF
$chartyaml

...
files:
  $chart: sha512:$shasum
EOF
)
echo "gpg --clearsign -o ${chart}.prov $@"
echo "$c" | gpg --clearsign -o ${chart}.prov $@
}


verify() {
  if is_help $1 ; then
    verify_usage
    return
  fi
  chart=$1
  shift
  gpg $@ --verify ${chart}.prov

  # verify checksum
  sha=$(shasum512 $chart)
  set +e
  grep "$chart: sha512:$sha" ${chart}.prov > /dev/null
  if [ $? -ne 0 ]; then
    echo "ERROR SHA verify error: sha512:$sha does not match ${chart}.prov"
    return 3
  fi
  set -e
  echo "plugin: Chart SHA verified. sha512:$sha"
}


shasum512() {
  openssl dgst -sha512 "$1" | awk '{ print $2 }'
}


if [[ $# < 1 ]]; then
  usage
  exit 1
fi


if ! type "gpg" > /dev/null; then
  echo "Command like 'gpg' client must be installed"
  exit 1
fi


case "${1:-"help"}" in
  "sign"):
    if [[ $# < 2 ]]; then
      push_usage
      echo "Error: Chart package required."
      exit 1
    fi
    shift
    archive=$1
    shift
    keyname=""
    passphrase=""
    keyring=""
    while (( "$#" )); do
      if [[ "$1" == "-u" ]] || [[ "$1" == "--local-user" ]]; then
        keyname="${1} ${2}"
        echo "Setting keyname to $keyname"
        shift 2
      fi
      if [[ "$1" == "--passphrase" ]] || [[ "$1" == "--passphrase-file" ]]; then
        passphrase="${1} ${2}"
        echo "Setting passphrase to ${passphrase}"
        shift 2
      fi
      if [[ "$1" == "--keyring" ]]; then
        keyring="${1} ${2}"
        echo "Setting keyring to ${keyring}"
        shift 2
      fi
    done
    sign $archive $keyname $passphrase $keyring
    ;;
  "verify"):
    if [[ $# < 2 ]]; then
      verify_usage
      echo "Error: Chart package required."
      exit 1
    fi
    shift
    archive=$1
    shift

    keyname=""
    keyring=""
    while (( "$#" )); do
      if [[ "$1" == "-u" ]] || [[ "$1" == "--local-user" ]]; then
        keyname="${1} ${2}"
        echo "Setting keyname to $keyname"
        shift 2
      fi
      if [[ "$1" == "--keyring" ]]; then
        keyring="--no-default-keyring ${1} ${2}"
        echo "Setting keyring to ${keyring}"
        shift 2
      fi
    done
    verify $archive $keyname $keyring
    ;;
  "help")
    usage
    ;;
  "--help")
    usage
    ;;
  "-h")
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac

exit 0
