#!/bin/bash
export THEOS=/home/liner0211/theos >> ~/.profile
echo “if [[ "$(umask)" = "0000" ]]; then” >> ~/.profile
echo “  umask 0022” >> ~/.profile
echo “fi” >> ~/.profile
source ~/.profile
