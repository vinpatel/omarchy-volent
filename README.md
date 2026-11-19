# VOLENT for Omarchy

Run a local [VOLENT](https://volent.dev) node on your Omarchy machine. VOLENT is
a sealed Linux VM image for running AI agents safely: one egress gate, a
journal of every side effect, and a signed attestation of what it is running.

This plugin gives you a `volent` command and a small bar indicator:

| command | what it does |
|---|---|
| `volent up [--image PATH\|DIR]` | verifies the image, boots it under QEMU/KVM as you, waits until the node reports healthy, and prints where its control API is |
| `volent status` | whether a node is running, its port, and its health document |
| `volent logs [-f] [-n N]` | the node's serial console |
| `volent down` | stops the node and deletes its scratch disk and credential |
| `volent verify [--image PATH\|DIR]` | the verification step alone; boots nothing |
| `volent request` | how to ask the VOLENT team for the image |

The bar indicator shows whether a node is running. Clicking it opens a terminal
running `volent up`, or `volent status` if a node is already up.

## Development keys

**The current VOLENT image (1.0.0) is signed with development Secure Boot keys.**
Those keys are disclosed and protect nothing. Treat a node started this way as
a local preview, not a production trust anchor. `volent up` says this every
time it boots such an image. It boots the image with plain UEFI firmware
(no Secure Boot), and the node reports that boot profile in its attestation.

## What `volent up` checks before it boots anything

1. The image manifest (`*.manifest`) carries an ed25519 signature
   (`*.manifest.sig`) that verifies against VOLENT's image key. The key's
   public half is pinned in `bin/volent` and is never downloaded.
2. The disk you have (`*.qcow2`, or else `*.raw`) has exactly the sha256 that
   the signed manifest records.

If either check fails, it refuses and boots nothing.

The node runs on a qcow2 overlay in `~/.local/state/volent/node/`, so your
image file is never written. Each `up` starts a fresh node with a new random
API credential. The node receives that credential the same way it would in a
cloud: as user-data from a metadata service. Here QEMU answers that request
inside the VM network, so nothing listens on your host for it. The control API
is forwarded to `127.0.0.1` only, on the first free port from 47800.

```sh
curl -H @"$HOME/.local/state/volent/node/auth-header" http://127.0.0.1:47800/v1/system/health
```

## Requirements

- An x86_64 machine with **KVM**: virtualization enabled in firmware, and
  `/dev/kvm` usable by your user.
- `qemu-system-x86_64`, `qemu-img`, and UEFI firmware. On Omarchy:
  `sudo pacman -S --needed qemu-base edk2-ovmf`
- `openssl`, `curl`, and coreutils, which Omarchy already has.

The plugin never uses sudo and writes only under `~/.local/state/volent`.

## Getting the image

The VOLENT image is not publicly downloadable. You get it after a short
sign-up at <https://app.volent.dev/signup>. Running `volent up` without an
image explains this and opens that page. If you would rather talk to someone
first, `volent request` opens the contact form at
<https://volent.dev/pricing/#contact>.

Put the files you receive in `~/.local/share/volent/images/`, or anywhere else
and pass `--image DIR`:

```
volent-1.0.0-dev-x86_64.qcow2        (or .raw)
volent-1.0.0-dev-x86_64.manifest
volent-1.0.0-dev-x86_64.manifest.sig
```

## Install

```sh
omarchy plugin add <repository-url> --enable
ln -s ~/.config/omarchy/plugins/volent/bin/volent ~/.local/bin/volent
```

The second line puts `volent` on your PATH. Omarchy plugins do not do this for
you, and you can skip it and run the full path instead.

## Remove

```sh
volent down
omarchy plugin remove volent
rm -f ~/.local/bin/volent
rm -rf ~/.local/state/volent    # the last console log
```

Your images in `~/.local/share/volent/images/` are left alone.

## Settings

These environment variables are optional: `VOLENT_IMAGES_DIR`, `VOLENT_PORT`
(first port to try), `VOLENT_MEM_MB` (default 2048), `VOLENT_CPUS` (default 2),
`VOLENT_TIMEOUT` (seconds to wait for health, default 180), and
`VOLENT_NO_BROWSER=1`.
