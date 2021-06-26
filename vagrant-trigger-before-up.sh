#!/bin/bash
set -euxo pipefail

./create_empty_box.sh

mkdir -p shared
python3 modules/pxe_server_register_machines.py get-machines-json >shared/machines.json
