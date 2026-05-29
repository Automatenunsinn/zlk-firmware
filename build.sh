pio run

$HOME/.platformio/packages/toolchain-atmelavr/bin/avr-objcopy -O binary ".pio/build/v1/firmware.elf" firmware_v1.bin
$HOME/.platformio/packages/toolchain-atmelavr/bin/avr-objcopy -O binary ".pio/build/v2/firmware.elf" firmware_v2.bin
$HOME/.platformio/packages/toolchain-atmelavr/bin/avr-objcopy -O binary ".pio/build/v3/firmware.elf" firmware_v3.bin
