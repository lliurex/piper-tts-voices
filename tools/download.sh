#!/bin/sh
set -eu

BASE_URL=https://huggingface.co/mijuanlo/piper-voices/resolve/main
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CATALOG="$ROOT/voices.json"
VOICE_FILE="$ROOT/debian/voice"

md5_of() {
    md5sum "$1" | cut -d' ' -f1
}

fetch() {
    url=$1
    dest=$2
    expected=$3
    if [ -f "$dest" ] && [ "$(md5_of "$dest")" = "$expected" ]; then
        echo "already downloaded: $dest"
        return 0
    fi
    echo "downloading $url"
    tmp="$dest.part"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$url"
    else
        wget -q -O "$tmp" "$url"
    fi
    actual=$(md5_of "$tmp")
    if [ "$actual" != "$expected" ]; then
        rm -f "$tmp"
        echo "ERROR: md5 mismatch for $dest (expected $expected, got $actual)" >&2
        return 1
    fi
    mv "$tmp" "$dest"
}

[ -f "$VOICE_FILE" ] || { echo "ERROR: $VOICE_FILE not found; run from a voice branch" >&2; exit 1; }
voice=$(head -n1 "$VOICE_FILE")
mkdir -p "$ROOT/files"
list=$(mktemp)
trap 'rm -f "$list"' EXIT
python3 - "$CATALOG" "$voice" > "$list" <<'PY'
import json
import sys

catalog = json.load(open(sys.argv[1]))
for path, info in catalog[sys.argv[2]]["files"].items():
    name = path.rsplit("/", 1)[-1]
    if path.endswith(".onnx") or path.endswith(".onnx.json") or name == "MODEL_CARD":
        print(path, info["md5_digest"])
PY
while read -r path expected; do
    name=${path##*/}
    fetch "$BASE_URL/$path" "$ROOT/files/$name" "$expected"
done < "$list"
rm -f "$list"
echo "voice ready: $voice"
