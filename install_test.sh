#!/bin/sh

set -ex

# Lint.
# $ shellcheck -s sh ./*.sh

# Test that we can install the latest version at the default location.
rm -f ~/.wakflo/bin/wakflo
unset WAKFLO_DIR
sh ./install.sh
~/.wakflo/bin/wakflo --version

# Test that we can install a specific version at a custom location.
rm -rf ~/wakflo-0.17.0
export WAKFLO_DIR="$HOME/wakflo-0.17.0"
./install.sh 0.17.0
~/wakflo-0.17.0/bin/wakflo --version | grep 0.17.0

# Test that upgrading versions work.
rm -f ~/.wakflo/bin/wakflo
unset WAKFLO_DIR
./install.sh 0.17.0
~/.wakflo/bin/wakflo --version | grep 0.17.0

unset WAKFLO_DIR
printf 'n\nn\n' | ./install.sh 0.16.0 || true
~/.wakflo/bin/wakflo --version | grep 0.17.0

unset WAKFLO_DIR
./install.sh 0.17.1
~/.wakflo/bin/wakflo --version | grep 0.17.1

# Re enable this test when we have multiple tagged versions to test against...
#unset WAKFLO_DIR
#./install.sh 1.0.0-alpha02.0
#~/.wakflo/bin/wakflo --version | grep 1.0.0-alpha02.0

unset WAKFLO_DIR
./install.sh 1.0.0-alpha3
~/.wakflo/bin/wakflo --version | grep 1.0.0-alpha3

unset WAKFLO_DIR
printf 'n\nn\n' | ./install.sh 0.17.0 || true
~/.wakflo/bin/wakflo --version | grep 1.0.0-alpha3
