# piper-tts-voices

Debian packages for Piper TTS voices. The reference catalog is
[huggingface.co/rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices);
the files for all eight voices are mirrored at
[huggingface.co/mijuanlo/piper-voices](https://huggingface.co/mijuanlo/piper-voices)
with the same path layout.

Each language is an independent native source package on two branches:

- `jammy/<idioma>` for Ubuntu jammy.
- `noble/<idioma>` for Ubuntu noble.

Both branches contain the same voice model. They differ only in the Debian
packaging metadata and version:

- jammy: `1.0.0+jammy`
- noble: `1.0.0+noble`

`master` contains only the shared content: `tools/download.sh`,
`tools/build.sh`, `voices.json` (the HuggingFace catalog used to verify
md5), `VOICE_LICENSES.md`, and this README.

## Voices

| Idioma | Ramas | Paquete | Voice | Locale | Quality | Speakers |
|--------|-------|---------|-------|--------|---------|----------|
| `ar` | `jammy/ar`, `noble/ar` | piper-tts-voices-ar | ar_JO-kareem-medium | ar_JO | medium | 1 |
| `ca` | `jammy/ca`, `noble/ca` | piper-tts-voices-ca | ca_ES-upc_pau-x_low | ca_ES | x_low | 1 |
| `de` | `jammy/de`, `noble/de` | piper-tts-voices-de | de_DE-thorsten-medium | de_DE | medium | 1 |
| `en` | `jammy/en`, `noble/en` | piper-tts-voices-en | en_US-lessac-medium | en_US | medium | 1 |
| `es` | `jammy/es`, `noble/es` | piper-tts-voices-es | es_ES-sharvard-medium | es_ES | medium | 2 |
| `fr` | `jammy/fr`, `noble/fr` | piper-tts-voices-fr | fr_FR-siwis-medium | fr_FR | medium | 1 |
| `it` | `jammy/it`, `noble/it` | piper-tts-voices-it | it_IT-paola-medium | it_IT | medium | 1 |
| `ru` | `jammy/ru`, `noble/ru` | piper-tts-voices-ru | ru_RU-denis-medium | ru_RU | medium | 1 |

The files are installed in `/usr/share/piper-voices` (the flat directory
used by piper-tts-server), and each voice's `MODEL_CARD` is installed in
`/usr/share/doc/piper-tts-voices-<idioma>/`.

## Voice selection

`piper-tts-server` resolves voices by name, with precedence over the
language: the `voice` parameter from `piper-tts-client --voice NAME`,
`spd-say -y NAME`, and `SET_SYNTHESIS_VOICE` used by applications such as
Firefox. The installed names (the model's `name` field) are:

    kareem, upc_pau (alias `pau`), thorsten, lessac, sharvard, siwis, paola, denis

    spd-say -y thorsten "Hello"   # German voice
    spd-say -L                    # list available voices

## Downloading voices

From a voice branch (`debian/voice` contains the catalog key):

    git checkout jammy/es
    tools/download.sh

or:

    git checkout noble/es
    tools/download.sh

This downloads `.onnx`, `.onnx.json`, and `MODEL_CARD` from the
`mijuanlo/piper-voices` mirror into `files/` (ignored by git), verifying
md5 against `voices.json`. Repeat on each branch. To add or update a voice,
first upload its files to the mirror using the same path.

## Building

`tools/build.sh` requires an explicit distribution selection:

    tools/build.sh --jammy              # all jammy voices
    tools/build.sh --noble              # all noble voices
    tools/build.sh --all                # all jammy and noble voices
    tools/build.sh --jammy --lang de    # only jammy/de
    tools/build.sh --noble --lang es    # only noble/es
    tools/build.sh --all --lang ca      # jammy/ca and noble/ca

Without arguments it prints help. An unknown language or an invalid
combination exits with an error. The script downloads anything missing from
the mirror, runs `dpkg-buildpackage -us -uc -b` on each selected branch, and
returns to the original branch. The `.deb` files are placed in the parent
directory.

## Installing

    sudo dpkg -i ../piper-tts-voices-*_all.deb

If the apt repository includes `piper-tts-server`, it recommends the eight
voice packages (`sudo apt install piper-tts-server` installs all of them);
with `--no-install-recommends`, none are installed.

The package restarts piper-tts.service when it is installed or upgraded and
the service is active, so the voice is available immediately. If the
service is not active, it is discovered on the next request. Optional
manual restart:

    sudo systemctl restart piper-tts.service

## Updating a single voice

    git checkout jammy/de
    # edit debian/changelog and debian/voice if needed
    tools/download.sh
    dpkg-buildpackage -us -uc -b

The equivalent noble branch is `noble/de`. The other branches and packages
are not modified.

## Licenses

Code, packaging, and tools in this repository are licensed under
GPL-3.0-or-later: https://www.gnu.org/licenses/gpl-3.0.html

`voices.json` is copied from rhasspy/piper-voices and is licensed under MIT:
https://opensource.org/license/mit

The voice model files are third-party content and are not covered by the
GPL. See [VOICE_LICENSES.md](VOICE_LICENSES.md) for a summary. The
authoritative license and attribution for each voice are in
`debian/copyright` on its branches and in the `MODEL_CARD` installed with
the package.
