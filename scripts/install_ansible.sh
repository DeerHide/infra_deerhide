#!/usr/bin/env bash

if [[ -d .venv ]]; then
    rm -rf .venv
fi

python3 -m venv .venv

source .venv/bin/activate

pip install ansible
pip install ansible-dev-tools
pip install jmespath