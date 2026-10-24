---
type: Development Guide
title: WSL development
description: Install Linux tooling and develop the SDK in WSL.
tags: [wsl, linux, swift, vscode]
sources:
  - resource: https://www.swift.org/install/linux/
    title: Official Swift Linux installation instructions
  - resource: ../../.github/workflows/ci.yml
    title: Project CI toolchains and checks
---

# WSL development

Use WSL 2 with Ubuntu 24.04. If WSL is not installed, run this in an administrator
PowerShell window on Windows, then finish the Ubuntu setup:

```powershell
wsl --install -d Ubuntu-24.04
```

Keep the repository in the Linux filesystem (for example `~/proj/`), not `/mnt/c`,
for better build performance.

## Install prerequisites inside Ubuntu

```bash
sudo apt update
sudo apt install -y git curl ca-certificates build-essential pkg-config gnupg
```

## Install Swift

Skip installation if your toolchain is already configured. Otherwise use Swiftly:

```bash
mkdir -p ~/Downloads/swiftly
cd ~/Downloads/swiftly
curl -fLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz"
tar zxf "swiftly-$(uname -m).tar.gz"
./swiftly init --quiet-shell-followup
source "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
hash -r
swiftly install 6.2.0
swiftly use 6.2.0
swift --version
```

Follow the initializer's instructions to install any missing system dependencies.
Swift 6.0 is the build/test CI baseline; 6.2.0 matches the formatting CI job and
includes `swift format`. Swift Package Manager and SourceKit-LSP come with the toolchain.

## Editor and checks

Install VS Code on Windows and Microsoft's WSL extension. Open the repository
from WSL with `code .`, then install the Swift.org Swift extension
(`swiftlang.swift-vscode`) in the WSL-connected window. Restart the editor if it
does not detect the newly installed toolchain.

From the repository root:

```bash
swift build
swift test
```

See [building and testing](../development/building-and-testing.md) for formatting
and opt-in live tests, and [documentation maintenance](../development/documentation.md)
for the separate documentation checker prerequisites.
WSL can build the Linux library and CLI; iOS/macOS application builds and
Apple-specific testing require macOS and Xcode.
