#!/bin/sh
# @version $Id: minica.sh 925 2018-11-01 23:19:10Z anrdaemon $

. "$( dirname "$( dirname "$( which "$0" )" )" )/ca-profile" || {
  echo "mca: Unable to load profile."
  exit 1
} >&2

## FIXME major version number goes here.
MCA_VER='$Version: 0.2 $.$Rev: 925 $'

## Version string.
_mca_version()
{
  echo "MiniCA, rev. ${MCA_VER}" | sed -Ee "s#\\\$[[:alpha:]]+(: ([^\\\$]+) )?\\\$#\\2#g;"
}

_name()
(
  case "$1" in
    req) _cmd=req; shift;;
    *) _cmd=x509;;
  esac
  test "$1" && test -e "$1" || return
  openssl $_cmd -in "$1" -noout -subject -multivalue-rdn -nameopt utf8,lname,sep_multiline,esc_ctrl,use_quote | {
    while IFS=" =" read -r _n _v; do
      case "$_n" in
        "commonName")
          echo "$_v" | sed -Ee "s#[^-[:alnum:][:space:]()+./=@_]+##g; s#[^-[:alnum:]()+.@]+#_#g;"
          break
          ;;
      esac
    done
  }
)

set -e

_C="$1"
shift

for i; do
  test ${next:-0} -gt 0 && {
    next=$(( $next - 1 ))
    continue
  }
  case $i in
    rsa)
        MCA_KEYTYPE=$1
        MCA_KEYLEN=$2
        next=1
        shift 2
      ;;
    days)
        MCA_KEYAGE=$2
        next=1
        shift 2
      ;;
    key)
        MCA_KEY="$( readlink -e "$2" )"
        next=1
        shift 2
      ;;
    cert)
        MCA_CERT="$( readlink -e "$2" )"
        next=1
        shift 2
      ;;
    *)
      # Drop out of parsing, if met with anything fancy
        break
      ;;
  esac
done

set +e

case $_C in
  init)
    # Draft converting current user into CA.
    test -e "$HOME/ca.key" && {
      echo "CA key exists. Aborting."
      exit 0
    } >&2
    mkdir --parents "$HOME/archive" "$HOME/bin" "$HOME/store/keys" "$HOME/tmp" 2> /dev/null || true
    touch -f "$HOME/.rnd" "$HOME/oid_list.txt" "$HOME/certdb.txt" 2> /dev/null || true
    echo "01" > "$HOME/.certserial"
    echo "01" > "$HOME/.crlserial"
    ;;
  *)
    test -x "${HOME}/bin/$_C" && (
        flock -n 9 || exit 1
        . "${HOME}/bin/$_C"
      ) 9> "$TMPDIR/.lock"
    ;;
esac
