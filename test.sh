#!/bin/bash
export THEOS=/opt/theos >> ~/.profile
echo “if [[ "$(umask)" = "0000" ]]; then” >> ~/.profile
echo “  umask 0022” >> ~/.profile
echo “fi” >> ~/.profile
source ~/.profile
