# wakflo-install

**One-line commands to install Wakflo on your system.**

[![Build Status](https://github.com/wakflo/wakflo-install/workflows/ci/badge.svg?branch=main)](https://github.com/wakflo/wakflo-install/actions)

## Install Latest Version

**With Shell:**

```sh
curl https://get.wakflo.ai -sSfL | sh
```

**With PowerShell:**  

```powershell
iwr https://win.wakflo.io -useb | iex
```

## Install Specific Version

**With Shell:**

```sh
curl https://get.wakflo.ai -sSfL | sh -s "2.2.1"
```

**With PowerShell:**

```powershell
$v="1.0.0"; iwr https://win.wakflo.io -useb | iex
```

## Install via Package Manager

**With [Homebrew](https://formulae.brew.sh/formula/wakflo):**

```sh
brew install wakflo wapm
```

**With [Scoop](https://github.com/ScoopInstaller/Main/blob/master/bucket/wakflo.json):**

```powershell
scoop install wakflo
```

**With [Chocolatey](https://chocolatey.org/packages/wakflo):**

**Wakflo is not yet available in Chocolatey, would you like to give us a hand? 🤗**

```powershell
choco install wakflo
```

**With [Cargo](https://crates.io/crates/wakflo-cli/):**


```sh
cargo install wakflo
```

## Environment Variables

- `WAKFLO_DIR` - The directory in which to install Wakflo. This defaults to
  `$HOME/.wakflo`. The executable is placed in `$WAKFLO_DIR/bin`. One
  application of this is a system-wide installation:

  **With Shell (`/usr/local`):**

  ```sh
  curl https://get.wakflo.io -sSfL | sudo WAKFLO_DIR=/usr/local sh
  ```

  **With PowerShell (`C:\Program Files\wakflo`):**

  ```powershell
  # Run as administrator:
  $env:WAKFLO_DIR = "C:\Program Files\wakflo"
  iwr https://win.wakflo.io -useb | iex
  ```

## Compatibility

- The Shell installer can be used on Windows via the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about).
