#!/bin/bash
python3 -c "data=open('bios.bin','rb').read(); print('local BIOS = \"' + ''.join('\\\\x%02x'%b for b in data) + '\"\\n\\nreturn BIOS')" > bios.lua
