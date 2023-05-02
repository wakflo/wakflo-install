#!/bin/sh

# This install script is intended to download and install the latest available
# release of Wasmer.
# It attempts to identify the current platform and an error will be thrown if
# the platform is not supported.
#
# Environment variables:
# - WAKFLO_DIR (optional): defaults to $HOME/.wakflo
#
# You can install using this script:
# $ curl https://raw.githubusercontent.com/wakflo/wakflo-install/main/install.sh | sh

# Installer script inspired by:
#  1) https://raw.githubusercontent.com/golang/dep/master/install.sh
#  2) https://sh.rustup.rs
#  3) https://yarnpkg.com/install.sh
#  4) https://raw.githubusercontent.com/brainsik/virtualenv-burrito/master/virtualenv-burrito.sh

reset="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
white="\033[37m"
bold="\e[1m"
dim="\e[2m"

RELEASES_URL="https://github.com/wakflo/wakflo-cli/releases"

WAKFLO_VERBOSE="verbose"
if [ -z "$WAKFLO_INSTALL_LOG" ]; then
  WAKFLO_INSTALL_LOG="$WAKFLO_VERBOSE"
fi

wakflo_download_json() {
  url="$2"

  # echo "Fetching $url.."
  if test -x "$(command -v curl)"; then
    response=$(curl -s -L -w 'HTTPSTATUS:%{http_code}' -H 'Accept: application/json' "$url")
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  elif test -x "$(command -v wget)"; then
    temp=$(mktemp)
    body=$(wget -q --header='Accept: application/json' -O - --server-response "$url" 2>"$temp")
    code=$(awk '/^  HTTP/{print $2}' <"$temp" | tail -1)
    rm "$temp"
  else
    wakflo_error "Neither curl nor wget was available to perform http requests"
    return 1
  fi
  if [ "$code" != 200 ]; then
    wakflo_error "File download failed with code $code"
    return 1
  fi

  eval "$1='$body'"
  return 0
}

wakflo_download_file() {
  url="$1"
  destination="$2"

  # echo "Fetching $url.."
  if test -x "$(command -v curl)"; then
    if [ "$WAKFLO_INSTALL_LOG" = "$WAKFLO_VERBOSE" ]; then
      code=$(curl --progress-bar -w '%{http_code}' -L "$url" -o "$destination")
      printf "\033[K\n\033[1A"
    else
      code=$(curl -s -w '%{http_code}' -L "$url" -o "$destination")
    fi
  elif test -x "$(command -v wget)"; then
    if [ "$WAKFLO_INSTALL_LOG" = "$WAKFLO_VERBOSE" ]; then
      code=$(wget --show-progress --progress=bar:force:noscroll -q -O "$destination" --server-response "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -1)
      printf "\033[K\n\033[1A"
    else
      code=$(wget --quiet -O "$destination" --server-response "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -1)
    fi
  else
    wakflo_error "Neither curl nor wget was available to perform http requests."
    return 1
  fi

  if [ "$code" = 404 ]; then
    wakflo_error "Your platform is not yet supported ($OS-$ARCH).$reset\nPlease open an issue on the project if you would like to use wakflo in your project: https://github.com/wakflo/wakflo-cli"
    return 1
  elif [ "$code" != 200 ]; then
    wakflo_error "File download failed with code $code"
    return 1
  fi
  return 0
}

wakflo_detect_profile() {
  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    echo "${PROFILE}"
    return
  fi

  local DETECTED_PROFILE
  DETECTED_PROFILE=''
  local SHELLTYPE
  SHELLTYPE="$(basename "/$SHELL")"

  if [ "$SHELLTYPE" = "bash" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "$SHELLTYPE" = "zsh" ]; then
    DETECTED_PROFILE="$HOME/.zshrc"
  elif [ "$SHELLTYPE" = "fish" ]; then
    DETECTED_PROFILE="$HOME/.config/fish/config.fish"
  fi

  if [ -z "$DETECTED_PROFILE" ]; then
    if [ -f "$HOME/.profile" ]; then
      DETECTED_PROFILE="$HOME/.profile"
    elif [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    elif [ -f "$HOME/.zshrc" ]; then
      DETECTED_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.config/fish/config.fish" ]; then
      DETECTED_PROFILE="$HOME/.config/fish/config.fish"
    fi
  fi

  if [ ! -z "$DETECTED_PROFILE" ]; then
    echo "$DETECTED_PROFILE"
  fi
}

wakflo_link() {

  WAKFLO_PROFILE="$(wakflo_detect_profile)"

  LOAD_STR="\n# Wasmer\nexport WAKFLO_DIR=\"$INSTALL_DIRECTORY\"\n[ -s \"\$WAKFLO_DIR/wakflo.sh\" ] && source \"\$WAKFLO_DIR/wakflo.sh\"\n"
  SOURCE_STR="# Wasmer config\nexport WAKFLO_DIR=\"$INSTALL_DIRECTORY\"\nexport WAKFLO_CACHE_DIR=\"\$WAKFLO_DIR/cache\"\nexport PATH=\"\$WAKFLO_DIR/bin:\$PATH:\$WAKFLO_DIR/globals/wakflo_packages/.bin\"\n"

  # We create the wakflo.sh file
  printf "$SOURCE_STR" >"$INSTALL_DIRECTORY/wakflo.sh"

  if [ -z "${WAKFLO_PROFILE-}" ]; then
    wakflo_error "Profile not found. Tried:\n* ${WAKFLO_PROFILE} (as defined in \$PROFILE)\n* ~/.bashrc\n* ~/.bash_profile\n* ~/.zshrc\n* ~/.profile.\n${reset}Append the following lines to the correct file yourself:\n${SOURCE_STR}"
    return 1
  else
    printf "Updating bash profile $WAKFLO_PROFILE\n"
    if ! grep -q 'wakflo.sh' "$WAKFLO_PROFILE"; then
      # if [[ $WAKFLO_PROFILE = *"fish"* ]]; then
      #   command fish -c 'set -U fish_user_paths $fish_user_paths ~/.wakflo/bin'
      # else
      command printf "$LOAD_STR" >>"$WAKFLO_PROFILE"
      # fi
      if [ "$WAKFLO_INSTALL_LOG" = "$WAKFLO_VERBOSE" ]; then
        printf "we've added the following to your $WAKFLO_PROFILE\n"
        echo "If you have a different profile please add the following:"
        printf "$dim$LOAD_STR$reset"
      fi
      wakflo_fresh_install=true
    else
      wakflo_warning "the profile already has Wasmer and has not been changed"
    fi

    version=$($INSTALL_DIRECTORY/bin/wakflo --version) || (
      wakflo_error "wakflo was installed, but doesn't seem to be working :("
      return 1
    )

    wakflo_install_status "check" "$version installed successfully ✓"

    if [ "$WAKFLO_INSTALL_LOG" = "$WAKFLO_VERBOSE" ]; then
      if [ "$wakflo_fresh_install" = true ]; then
        printf "wakflo & wapm will be available the next time you open the terminal.\n"
        printf "If you want to have the commands available now please execute:\n\nsource $INSTALL_DIRECTORY/wakflo.sh$reset\n"
      fi
    fi
  fi
  return 0
}

initArch() {
  ARCH=$(uname -m)
  case $ARCH in
  amd64) ARCH="amd64" ;;
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="aarch64" ;;
  riscv64) ARCH="riscv64" ;;
  arm64) ARCH="arm64" ;; # This is for the macOS M1 ARM chips
  *)
    wakflo_error "The system architecture (${ARCH}) is not yet supported by this installation script."
    exit 1
    ;;
  esac
  # echo "ARCH = $ARCH"
}

initOS() {
  OS=$(uname | tr '[:upper:]' '[:lower:]')
  case "$OS" in
  darwin) OS='darwin' ;;
  linux) OS='linux' ;;
  freebsd) OS='freebsd' ;;
  # mingw*) OS='windows';;
  # msys*) OS='windows';;
  *)
    printf "$red> The OS (${OS}) is not supported by this installation script.$reset\n"
    exit 1
    ;;
  esac
}

wakflo_install() {
  magenta1="${reset}\033[34;1m"
  magenta2=""
  magenta3=""

  if which wakflo >/dev/null; then
    printf "${reset}Welcome to the Wasmer bash installer!$reset\n"
  else
    printf "${reset}Welcome to the Wasmer bash installer!$reset\n"
    if [ "$WAKFLO_INSTALL_LOG" = "$WAKFLO_VERBOSE" ]; then
      printf "
${magenta1}               ww
${magenta1}               wwwww
${magenta1}        ww     wwwwww  w
${magenta1}        wwwww      wwwwwwwww
${magenta1}ww      wwwwww  w     wwwwwww
${magenta1}wwwww      wwwwwwwwww   wwwww
${magenta1}wwwwww  w      wwwwwww  wwwww
${magenta1}wwwwwwwwwwwwww   wwwww  wwwww
${magenta1}wwwwwwwwwwwwwww  wwwww  wwwww
${magenta1}wwwwwwwwwwwwwww  wwwww  wwwww
${magenta1}wwwwwwwwwwwwwww  wwwww  wwwww
${magenta1}wwwwwwwwwwwwwww  wwwww   wwww
${magenta1}wwwwwwwwwwwwwww  wwwww
${magenta1}   wwwwwwwwwwww   wwww
${magenta1}       wwwwwwww
${magenta1}           wwww
${reset}
"
    fi
  fi

  wakflo_download $1 && wakflo_link
  wakflo_reset
}

wakflo_reset() {
  unset -f wakflo_install semver_compare wakflo_reset wakflo_download_json wakflo_link wakflo_detect_profile wakflo_download_file wakflo_download wakflo_verify_or_quit
}

version() {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

semverParseInto() {
  local RE='v?([0-9]+)[.]([0-9]+)[.]([0-9]+)([.0-9A-Za-z-]*)'

  # # strip word "v" if exists
  # version=$(echo "${1//v/}")

  #MAJOR
  eval $2=$(echo $1 | sed -E "s#$RE#\1#")
  #MINOR
  eval $3=$(echo $1 | sed -E "s#$RE#\2#")
  #MINOR
  eval $4=$(echo $1 | sed -E "s#$RE#\3#")
  #SPECIAL
  eval $5=$(echo $1 | sed -E "s#$RE#\4#")
}

###
# Code inspired (copied partially and improved) with attributions from:
# https://github.com/cloudflare/semver_bash/blob/master/semver.sh
# https://gist.github.com/Ariel-Rodriguez/9e3c2163f4644d7a389759b224bfe7f3
###
semver_compare() {
  local version_a version_b

  local MAJOR_A=0
  local MINOR_A=0
  local PATCH_A=0
  local SPECIAL_A=0

  local MAJOR_B=0
  local MINOR_B=0
  local PATCH_B=0
  local SPECIAL_B=0

  semverParseInto $1 MAJOR_A MINOR_A PATCH_A SPECIAL_A
  semverParseInto $2 MAJOR_B MINOR_B PATCH_B SPECIAL_B

  # Check if our version is higher
  if [ $MAJOR_A -gt $MAJOR_B ]; then
    echo 1 && return 0
  fi

  if [ $MAJOR_A -eq $MAJOR_B ]; then
    if [ $MINOR_A -gt $MINOR_B ]; then
      echo 1 && return 0
    elif [ $MINOR_A -eq $MINOR_B ]; then
      if [ $PATCH_A -gt $PATCH_B ]; then
        echo 1 && return 0
      elif [ $PATCH_A -eq $PATCH_B ]; then
        if [ -n "$SPECIAL_A" ] && [ -z "$SPECIAL_B" ]; then
          # if the version we're targeting does not have a tag and our current
          # version does, we should upgrade because no tag > tag
          echo -1 && return 0
        elif [ "$SPECIAL_A" \> "$SPECIAL_B" ]; then
          echo 1 && return 0
        elif [ "$SPECIAL_A" = "$SPECIAL_B" ]; then
          # complete match
          echo 0 && return 0
        fi
      fi
    fi
  fi

  # if we're here we know that the target verison cannot be less than or equal to
  # our current version, therefore we upgrade

  echo -1 && return 0
}

wakflo_download() {
  # identify platform based on uname output
  initArch || return 1
  initOS || return 1

  # assemble expected release artifact name
  BINARY="wakflo-${OS}-${ARCH}.tar.gz"

  # add .exe if on windows
  # if [ "$OS" = "windows" ]; then
  #     BINARY="$BINARY.exe"
  # fi

  wakflo_install_status "downloading" "wakflo-$OS-$ARCH"
  if [ $# -eq 0 ]; then
    # The version was not provided, assume latest
    wakflo_download_json LATEST_RELEASE "$RELEASES_URL/latest" || return 1
    WAKFLO_RELEASE_TAG=$(echo "${LATEST_RELEASE}" | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
    printf "Latest release: ${WAKFLO_RELEASE_TAG}\n"
  else
    WAKFLO_RELEASE_TAG="${1}"
    printf "Installing provided version: ${WAKFLO_RELEASE_TAG}\n"
  fi

  if which $INSTALL_DIRECTORY/bin/wakflo >/dev/null; then
    WAKFLO_VERSION=$($INSTALL_DIRECTORY/bin/wakflo --version | sed 's/wakflo //g')
    printf "Wasmer already installed in ${INSTALL_DIRECTORY} with version: ${WAKFLO_VERSION}\n"

    WAKFLO_COMPARE=$(semver_compare $WAKFLO_VERSION $WAKFLO_RELEASE_TAG)
    case $WAKFLO_COMPARE in
    # WAKFLO_VERSION = WAKFLO_RELEASE_TAG
    0)
      if [ $# -eq 0 ]; then
        wakflo_warning "wakflo is already installed in the latest version: ${WAKFLO_RELEASE_TAG}"
      else
        wakflo_warning "wakflo is already installed with the same version: ${WAKFLO_RELEASE_TAG}"
      fi
      printf "Do you want to force the installation?"
      wakflo_verify_or_quit || return 1
      ;;
      # WAKFLO_VERSION > WAKFLO_RELEASE_TAG
    1)
      wakflo_warning "the selected version (${WAKFLO_RELEASE_TAG}) is lower than current installed version ($WAKFLO_VERSION)"
      printf "Do you want to continue installing Wasmer $WAKFLO_RELEASE_TAG?"
      wakflo_verify_or_quit || return 1
      ;;
      # WAKFLO_VERSION < WAKFLO_RELEASE_TAG (we continue)
    -1) ;;
    esac
  fi

  # fetch the real release data to make sure it exists before we attempt a download
  wakflo_download_json RELEASE_DATA "$RELEASES_URL/tag/$WAKFLO_RELEASE_TAG" || return 1

  BINARY_URL="$RELEASES_URL/download/$WAKFLO_RELEASE_TAG/$BINARY"
  DOWNLOAD_FILE=$(mktemp -t wakflo.XXXXXXXXXX)

  printf "Downloading archive from ${BINARY_URL}\n"

  wakflo_download_file "$BINARY_URL" "$DOWNLOAD_FILE" || return 1
  # echo -en "\b\b"
  printf "\033[K\n\033[1A"

  # windows not supported yet
  # if [ "$OS" = "windows" ]; then
  #     INSTALL_NAME="$INSTALL_NAME.exe"
  # fi

  # echo "Moving executable to $INSTALL_DIRECTORY/$INSTALL_NAME"

  wakflo_install_status "installing" "${INSTALL_DIRECTORY}"

  mkdir -p $INSTALL_DIRECTORY

  # Untar the wakflo contents in the install directory
  tar -C $INSTALL_DIRECTORY -zxf $DOWNLOAD_FILE
  return 0
}

wakflo_error() {
  printf "$bold${red}error${white}: $1${reset}\n"
}

wakflo_install_status() {
  printf "$bold${green}${1}${white}: $2${reset}\n"
}

wakflo_warning() {
  printf "$bold${yellow}warning${white}: $1${reset}\n"
}

wakflo_verify_or_quit() {
  if [ -n "$BASH_VERSION" ]; then
    # If we are in bash, we can use read -n
    read -p "$1 [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      wakflo_error "installation aborted"
      return 1
    fi
    return 0
  fi

  read -p "$1 [y/N]" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
    wakflo_error "installation aborted"
    return 1
    ;;
  *) echo "Please answer yes or no." ;;
  esac

  return 0
}

# determine install directory if required
if [ -z "$WAKFLO_DIR" ]; then
  # If WAKFLO_DIR is not present
  INSTALL_DIRECTORY="$HOME/.wakflo"
else
  # If WAKFLO_DIR is present
  INSTALL_DIRECTORY="${WAKFLO_DIR}"
fi

wakflo_install $1 # $2