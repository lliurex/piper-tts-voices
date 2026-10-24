#!/bin/sh
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ALL_LANGUAGES="ar ca de en es fr it ru"

usage() {
    cat <<'EOF'
Usage: tools/build.sh --jammy|--noble|--all [--lang <idioma>]

Options:
  --jammy          build all jammy/<idioma> branches
  --noble          build all noble/<idioma> branches
  --all            build jammy/<idioma> and noble/<idioma>
  --lang <idioma>  build only the selected language (ar ca de en es fr it ru)
  -h, --help       show this help

Examples:
  tools/build.sh --jammy
  tools/build.sh --noble
  tools/build.sh --all
  tools/build.sh --jammy --lang de
  tools/build.sh --noble --lang es
  tools/build.sh --all --lang ca
EOF
}

distro=
language=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --jammy|--noble|--all)
            if [ -n "$distro" ]; then
                echo "ERROR: choose only one of --jammy, --noble or --all" >&2
                usage >&2
                exit 2
            fi
            distro=${1#--}
            ;;
        --lang)
            shift
            if [ "$#" -eq 0 ] || [ -z "$1" ]; then
                echo "ERROR: --lang requires a language" >&2
                usage >&2
                exit 2
            fi
            if [ -n "$language" ]; then
                echo "ERROR: --lang can only be used once" >&2
                usage >&2
                exit 2
            fi
            language=$1
            case " $ALL_LANGUAGES " in
                *" $language "*) ;;
                *)
                    echo "ERROR: unknown language '$language'" >&2
                    usage >&2
                    exit 2
                    ;;
            esac
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument '$1'" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [ -z "$distro" ]; then
    if [ -n "$language" ]; then
        echo "ERROR: --lang requires --jammy, --noble or --all" >&2
        usage >&2
        exit 2
    fi
    usage
    exit 0
fi

if [ -z "$language" ]; then
    languages=$ALL_LANGUAGES
else
    languages=$language
fi

branches=
case "$distro" in
    jammy|noble)
        for lang in $languages; do
            branches="$branches $distro/$lang"
        done
        ;;
    all)
        for lang in $languages; do
            branches="$branches jammy/$lang noble/$lang"
        done
        ;;
esac

cd "$ROOT"
original=$(git rev-parse --abbrev-ref HEAD)

restore() {
    git checkout "$original"
    echo "back on branch $original"
}
trap restore EXIT

for branch in $branches; do
    echo "=== building $branch"
    git checkout "$branch"
    tools/download.sh
    dpkg-buildpackage -us -uc -b
done
