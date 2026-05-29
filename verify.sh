#!/bin/bash

sha1sum -c <<EOF
0624c2145589f85f39aa97e9f1a6cd334ab597e7  firmware_v1.bin
db439d2a95d3891e4bb2c859075589a622b43c1c  firmware_v2.bin
819483a79126ba3f4a0e0ad572caa618bc25b26e  firmware_v3.bin
EOF

# Check the exit status of the previous command
if [ $? -ne 0 ]; then
    echo "FAIL: One or more hashes did not match."
    exit 1
fi

echo "All firmware files verified successfully."
