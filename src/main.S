#include <avr/io.h>

/* Register Definitions */
#define ent0 r0
#define ent1 r1
#define ent2 r2
#define ent3 r3
#define loop_ext r4
#define loop_int r5
#define bsn0 r6
#define bsn1 r7
#define bsn2 r8
#define bsn3 r9
#define zero r10
#define sn0 r12
#define sn1 r13
#define sn2 r14
#define sn3 r15
#define temp r16
#define arg1 r17
#define res  r18
#define cnt  r19
#define flags r20
#define s0 r21
#define s1 r22
#define s2 r23
#define s3 r24
#define s4 r25
#define s5 r26
#define s6 r27
#define s7 r28
#define s8 r29
#define s9 r30
#define s10 r31

#ifdef NEW_KEY
#define KEY_1_01 0x61
#define KEY_1_02 0x4F
#define KEY_1_03 0x9A
#define KEY_1_04 0x72
#define KEY_1_05 0x5B

#define KEY_2_01 0x55
#define KEY_2_02 0x14
#define KEY_2_03 0xE5
#define KEY_2_04 0xBD
#define KEY_2_05 0x8c
#else // OLD_KEY
#define KEY_1_01 0x29
#define KEY_1_02 0x91
#define KEY_1_03 0xA7
#define KEY_1_04 0xF1
#define KEY_1_05 0x6B

#define KEY_2_01 0x33
#define KEY_2_02 0xFB
#define KEY_2_03 0xC7
#define KEY_2_04 0x52
#define KEY_2_05 0xC9
#endif

#ifdef NEW_KEY
#define AUTH_1_01 0x89
#define AUTH_1_02 0xED
#define AUTH_1_03 0xC3
#define AUTH_1_04 0xAD
#define AUTH_1_05 0x8F
#define AUTH_1_06 0x61
#define AUTH_1_07 0x32
#else // OLD_AUTH
#define AUTH_1_01 0x1D
#define AUTH_1_02 0xE9
#define AUTH_1_03 0x43
#define AUTH_1_04 0x3F
#define AUTH_1_05 0xB8
#define AUTH_1_06 0x29
#define AUTH_1_07 0x32
#endif

#ifdef NEW_KEY
#define AUTH_ROT_1_01 0x67
#define AUTH_ROT_1_02 0x3D
#define AUTH_ROT_1_03 0xA5
#define AUTH_ROT_1_04 0x77
#define AUTH_ROT_1_05 0x54
#define AUTH_ROT_1_06 0x55
#else // OLD_AUTH_ROT
#define AUTH_ROT_1_01 0x8E
#define AUTH_ROT_1_02 0x65
#define AUTH_ROT_1_03 0xE1
#define AUTH_ROT_1_04 0xA3
#define AUTH_ROT_1_05 0x74
#define AUTH_ROT_1_06 0x33
#endif

/* Serial Number Configuration */
#ifndef CASE_ID_01
#define CASE_ID_01 0x12
#endif
#ifndef CASE_ID_23
#define CASE_ID_23 0x34
#endif

#ifndef ZL_NUM_0
#define ZL_NUM_0 0x09
#endif
#ifndef ZL_NUM_12
#define ZL_NUM_12 0x99
#endif
#ifndef ZL_NUM_34
#define ZL_NUM_34 0x99
#endif
#ifndef ZL_NUM_56
#define ZL_NUM_56 0x99
#endif
#ifndef ZL_NUM_78
#define ZL_NUM_78 0x99
#endif

#ifndef DATE_0
#define DATE_0 0x01
#endif
#ifndef DATE_1
#define DATE_1 0x98
#endif

.section .text

.global main
main:
    rjmp reset
    reti

/* 0x04: Bit-banged Handshake Protocol: Start Transmission */
comm_tx_start:
    sbi	_SFR_IO_ADDR(PORTB), 4
comm_tx_start_wait:
    sbis	_SFR_IO_ADDR(PINB), 3
    rjmp comm_tx_start_wait
    ori	flags, 0x20
    ret

/* 0x0E: EEPROM Access Helpers */
eeprom_read_next:
    inc	temp
eeprom_read_at_temp:
    out	0x22, zero
    out	0x21, temp
    sbi	_SFR_IO_ADDR(EECR), 0
    ret

/* 0x18: EEPROM Write and Increment */
eeprom_write_wait_and_inc:
    inc	temp
eeprom_write_at_temp:
    out	0x22, zero
    out	0x21, temp
    sbi	_SFR_IO_ADDR(EECR), 2 /* EEPE */
    sbi	_SFR_IO_ADDR(EECR), 1 /* EEMPE */
eeprom_wait_loop:
    sbic	_SFR_IO_ADDR(EECR), 1
    rjmp eeprom_wait_loop
    ret

/* 0x28: Timing Delay */
comm_delay:
    eor	arg1, arg1
    ldi	res, 0x02
delay_inner_loop:
    nop
    dec	arg1
    brne delay_inner_loop
    dec	res
    brne delay_inner_loop
    ret

/* 0x38: Crypto Key Application 1 */
crypto_apply_key_1:
    ldi	temp, KEY_1_01
    eor	s0, temp
    ldi	temp, KEY_1_02
    eor	s1, temp
    ldi	temp, KEY_1_03
    eor	s2, temp
    ldi	temp, KEY_1_04
    eor	s3, temp
    ldi	temp, KEY_1_05
    eor	s4, temp
    ret

/* 0x4E: Crypto State Update */
crypto_update_state:
    mov	temp, s0
    rcall crypto_lcg_step_1
    mov	s0, res
    mov	temp, s1
    rcall crypto_lcg_step_1
    mov	s1, res
    mov	temp, s2
    rcall crypto_lcg_step_1
    mov	s2, res
    mov	temp, s3
    rcall crypto_lcg_step_1
    mov	s3, res
    mov	temp, s4
    rcall crypto_lcg_step_1
    mov	s4, res
    ret

/* 0x6E: Receive State */
comm_rx_state:
    rcall comm_rx_byte
    mov	s0, temp
    rcall comm_rx_byte
    mov	s1, temp
    rcall comm_rx_byte
    mov	s2, temp
    rcall comm_rx_byte
    mov	s3, temp
    ret

/* 0x80: Receive Byte */
comm_rx_byte:
    ldi	cnt, 0x08
rx_bit_loop:
    wdr
    rcall comm_delay
    add	temp, temp
    sbic	_SFR_IO_ADDR(PINB), 3
    ori	temp, 0x01
    sbis	_SFR_IO_ADDR(PINB), 4
    rjmp rx_bit_low
    cbi	_SFR_IO_ADDR(PORTB), 4
    rjmp rx_bit_done
rx_bit_low:
    sbi	_SFR_IO_ADDR(PORTB), 4
rx_bit_done:
    dec	cnt
    brne rx_bit_loop
    ret

/* 0x9C: Transmit Byte */
comm_tx_byte:
    ldi	cnt, 0x08
tx_bit_loop:
    wdr
    add	temp, temp
    brcc tx_bit_low
    sbi	_SFR_IO_ADDR(PORTB), 4
    rjmp tx_bit_done
tx_bit_low:
    cbi	_SFR_IO_ADDR(PORTB), 4
tx_bit_done:
    rcall comm_wait_ack
    dec	cnt
    brne tx_bit_loop
    ret

/* 0xB2: Wait for ACK */
comm_wait_ack:
    sbrc	flags, 5
    rjmp wait_for_pb_low
wait_for_pb_high:
    sbis	_SFR_IO_ADDR(PINB), 3
    rjmp wait_for_pb_high
    ori	flags, 0x20
    rjmp wait_for_pb_done
wait_for_pb_low:
    sbic	_SFR_IO_ADDR(PINB), 3
    rjmp wait_for_pb_low
    andi	flags, 0xDF
wait_for_pb_done:
    ret

/* 0xC6: LCG Step 1 */
crypto_lcg_step_1:
    eor	res, res
    ldi	arg1, 0x25
    ldi	cnt, 0x08
lcg_loop_1:
    add	res, res
    add	arg1, arg1
    brcc lcg_step_1_no_add
    add	res, temp
lcg_step_1_no_add:
    dec	cnt
    brne lcg_loop_1
    ldi	arg1, 0x05
    add	res, arg1
    ret

/* 0xDE: LCG Step 2 */
crypto_lcg_step_2:
    eor	res, res
    ldi	arg1, 0xAD
    ldi	cnt, 0x08
lcg_loop_2:
    add	res, res
    add	arg1, arg1
    brcc lcg_step_2_no_add
    add	res, temp
lcg_step_2_no_add:
    dec	cnt
    brne lcg_loop_2
    ldi	arg1, 0x9F
    add	res, arg1
    ret

/* 0xF6: Crypto Apply Key 2 */
crypto_apply_key_2:
    ldi	temp, KEY_2_01
    eor	s0, temp
    ldi	temp, KEY_2_02
    eor	s1, temp
    ldi	temp, KEY_2_03
    eor	s2, temp
    ldi	temp, KEY_2_04
    eor	s3, temp
    ldi	temp, KEY_2_05
    eor	s4, temp
    ret

/* 0x10C: Transmit State */
comm_tx_state:
    mov	temp, s0
    rcall comm_tx_byte
    mov	temp, s1
    rcall comm_tx_byte
    mov	temp, s2
    rcall comm_tx_byte
    mov	temp, s3
    rcall comm_tx_byte
    mov	temp, s4
    rcall comm_tx_byte
    ret

/* 0x122: System Reset and Initialization */
reset:
    ldi	temp, 0xFF
    out	_SFR_IO_ADDR(SPL), temp
    ldi	temp, 0x02
    out	_SFR_IO_ADDR(SPH), temp
    ldi	temp, 0x80
    sts	0x61, temp /* CLKPR enable */
    ldi	temp, 0x03
    sts	0x61, temp /* CLKPR set */
    eor	zero, zero
    out	0x22, zero /* EEARH */
    out	0x21, zero /* EEARL */
    ldi	temp, 0xFF
    out	_SFR_IO_ADDR(DDRD), temp
    out	_SFR_IO_ADDR(DDRC), temp
    out	_SFR_IO_ADDR(PORTD), zero
    out	_SFR_IO_ADDR(PORTC), zero
    out	_SFR_IO_ADDR(PORTB), zero
    ldi	temp, 0xF7
    out	_SFR_IO_ADDR(DDRB), temp
    wdr
    lds	temp, 0x60 /* WDTCSR */
    ori	temp, 0x18
    sts	0x60, temp
    ldi	temp, 0x08
    sts	0x60, temp

/* 0x15E: Main Idle Loop */
idle_wait:
    eor	temp, temp
    ldi	arg1, 0x01
entropy_loop:
    wdr
    add	ent0, arg1
    adc	ent1, temp
    sub	ent2, arg1
    adc	ent3, temp
    sbis	_SFR_IO_ADDR(PINB), 3
    rjmp entropy_loop
    sbi	_SFR_IO_ADDR(PORTB), 4
    rcall comm_rx_byte
    cpi	temp, 0x31
    breq jump_auth1
    cpi	temp, 0x32
    breq jump_auth2
    cpi	temp, 0x33
    breq jump_auth_write
    cpi	temp, 0x34
    breq cmd_update_sn
    cpi	temp, 0x35
    breq cmd_write_nvram
    cpi	temp, 0x36
    breq cmd_read_nvram
    cbi	_SFR_IO_ADDR(PORTB), 4
    rjmp idle_wait

jump_auth1:
    rjmp cmd_auth_step_1
jump_auth2:
    rjmp cmd_auth_step_2
jump_auth_write:
    rjmp cmd_auth_write

/* NVRAM Write Command */
cmd_write_nvram:
    rcall comm_rx_byte
    cpi	temp, 0x20
    brmi cmd_nvram_exit
    cpi	temp, 0x40
    brcc cmd_nvram_exit
    out	0x22, zero
    out	0x21, temp
    rcall comm_rx_byte
    out	_SFR_IO_ADDR(EEDR), temp
    sbi	_SFR_IO_ADDR(EECR), 2 /* EEPE */
    sbi	_SFR_IO_ADDR(EECR), 1 /* EEMPE */
cmd_nvram_exit:
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    rjmp idle_wait

/* NVRAM Read Command */
cmd_read_nvram:
    rcall comm_rx_byte
    cpi	temp, 0x20
    brmi cmd_nvram_exit
    cpi	temp, 0x40
    brcc cmd_nvram_exit
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    out	0x22, zero
    out	0x21, temp
    sbi	_SFR_IO_ADDR(EECR), 0
    in	temp, _SFR_IO_ADDR(EEDR)
    rcall comm_delay
    rcall comm_tx_start
    rjmp comm_tx_byte_exit_in_step1

/* 0x1CE: Serial Number Update */
cmd_update_sn:
    rcall comm_rx_byte
    mov	s0, temp
    rcall comm_rx_byte
    mov	s1, temp
    rcall comm_rx_byte
    mov	s2, temp
    rcall comm_rx_byte
    mov	s3, temp
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    ldi	temp, 0x4B
    rcall eeprom_read_at_temp
    in	temp, _SFR_IO_ADDR(EEDR)
    cpi	temp, 0x00
    brne auth1_init_state
    ldi	temp, 0x02
    rcall eeprom_read_next
    in	sn0, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	sn1, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	sn2, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	sn3, _SFR_IO_ADDR(EEDR)
    inc	temp
    rcall eeprom_read_next
    in	bsn0, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	bsn1, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	bsn2, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	bsn3, _SFR_IO_ADDR(EEDR)
    cp	bsn0, sn0
    brcs update_sn_backup
    cp	bsn1, sn1
    brcs update_sn_backup
    cp	bsn2, sn2
    brcs update_sn_backup
    cp	bsn3, sn3
    brcs update_sn_backup
    rjmp auth1_init_state
update_sn_backup:
    ldi	temp, 0x07
    out	_SFR_IO_ADDR(EEDR), sn0
    rcall eeprom_write_wait_and_inc
    out	_SFR_IO_ADDR(EEDR), sn1
    rcall eeprom_write_wait_and_inc
    out	_SFR_IO_ADDR(EEDR), sn2
    rcall eeprom_write_wait_and_inc
    out	_SFR_IO_ADDR(EEDR), sn3
    rcall eeprom_write_wait_and_inc

/* Authentication Step 1 */
auth1_init_state:
    ldi	temp, 0x46
    rcall eeprom_read_next
    in	s4, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s5, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s6, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s7, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s8, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s9, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s10, _SFR_IO_ADDR(EEDR)
    rjmp auth1_start

cmd_auth_step_1:
    rcall comm_rx_state
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    ldi	temp, 0x3F
    rcall eeprom_read_next
    in	s4, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s5, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s6, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s7, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s8, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s9, _SFR_IO_ADDR(EEDR)
    rcall eeprom_read_next
    in	s10, _SFR_IO_ADDR(EEDR)

auth1_start:
    ldi	temp, 0x80
    sts	0x61, temp
    ldi	temp, 0x00
    sts	0x61, temp
    rcall crypto_apply_key_1
    ldi	temp, AUTH_1_01
    eor	s5, temp
    ldi	temp, AUTH_1_02
    eor	s6, temp
    ldi	temp, AUTH_1_03
    eor	s7, temp
    ldi	temp, AUTH_1_04
    eor	s8, temp
    ldi	temp, AUTH_1_05
    eor	s9, temp
    ldi	temp, AUTH_1_06
    eor	s10, temp
    ldi	temp, AUTH_1_07
    mov	loop_ext, temp
auth1_outer_loop:
    wdr
    rcall crypto_update_state
    mov	temp, s5
    rcall crypto_lcg_step_1
    mov	s5, res
    mov	temp, s6
    rcall crypto_lcg_step_1
    mov	s6, res
    mov	temp, s7
    rcall crypto_lcg_step_1
    mov	s7, res
    mov	temp, s8
    rcall crypto_lcg_step_1
    mov	s8, res
    mov	temp, s9
    rcall crypto_lcg_step_1
    mov	s9, res
    mov	temp, s10
    rcall crypto_lcg_step_1
    mov	s10, res
    ldi	temp, 0x03
    mov	loop_int, temp
auth1_rotate_loop:
    clc
    adc	s10, s10
    adc	s9, s9
    adc	s8, s8
    adc	s7, s7
    adc	s6, s6
    adc	s5, s5
    adc	s4, s4
    adc	s3, s3
    adc	s2, s2
    adc	s1, s1
    adc	s0, s0
    brcc auth1_rotate_done
    ori	s10, 0x01
auth1_rotate_done:
    dec	loop_int
    brne auth1_rotate_loop
    dec	loop_ext
    brne auth1_outer_loop
    rcall crypto_apply_key_2
    ldi	temp, AUTH_ROT_1_01
    eor	s5, temp
    ldi	temp, AUTH_ROT_1_02
    eor	s6, temp
    ldi	temp, AUTH_ROT_1_03
    eor	s7, temp
    ldi	temp, AUTH_ROT_1_04
    eor	s8, temp
    ldi	temp, AUTH_ROT_1_05
    eor	s9, temp
    ldi	temp, AUTH_ROT_1_06
    eor	s10, temp
    ldi	temp, 0x80
    sts	0x61, temp
    ldi	temp, 0x03
    sts	0x61, temp
    wdr
    rcall comm_tx_start
    rcall comm_tx_state
    mov	temp, s5
    rcall comm_tx_byte
    mov	temp, s6
    rcall comm_tx_byte
    mov	temp, s7
    rcall comm_tx_byte
    mov	temp, s8
    rcall comm_tx_byte
    mov	temp, s9
    rcall comm_tx_byte
    mov	temp, s10
comm_tx_byte_exit_in_step1:
    rcall comm_tx_byte
    cbi	_SFR_IO_ADDR(PORTB), 4
    rcall comm_delay
    rjmp idle_wait

/* Authentication Step 2 */
cmd_auth_step_2:
    rcall comm_rx_state
    rcall comm_rx_byte
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    out	0x22, zero
    out	0x21, temp
    sbi	_SFR_IO_ADDR(EECR), 0
    in	s4, _SFR_IO_ADDR(EEDR)
    ldi	temp, 0x80
    sts	0x61, temp
    ldi	temp, 0x00
    sts	0x61, temp
    rcall crypto_apply_key_1
    ldi	temp, 0x32
    mov	loop_ext, temp
auth2_outer_loop:
    wdr
    rcall crypto_update_state
    ldi	temp, 0x03
    mov	loop_int, temp
auth2_rotate_loop:
    clc
    adc	s4, s4
    adc	s3, s3
    adc	s2, s2
    adc	s1, s1
    adc	s0, s0
    brcc auth2_rotate_done
    ori	s4, 0x01
auth2_rotate_done:
    dec	loop_int
    brne auth2_rotate_loop
    dec	loop_ext
    brne auth2_outer_loop
    rcall crypto_apply_key_2
    ldi	temp, 0x80
    sts	0x61, temp
    ldi	temp, 0x03
    sts	0x61, temp
    wdr
    rcall comm_tx_start
    rcall comm_tx_state
    cbi	_SFR_IO_ADDR(PORTB), 4
    rcall comm_delay
    rjmp idle_wait

/* Authenticated Write Command */
cmd_auth_write:
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    rcall comm_delay
    wdr
    rcall comm_tx_start
    mov	temp, ent0
    rcall comm_tx_byte
    mov	temp, ent1
    rcall comm_tx_byte
    mov	temp, ent2
    rcall comm_tx_byte
    mov	temp, ent3
    rcall comm_tx_byte
    wdr
    cbi	_SFR_IO_ADDR(PORTB), 4
    rcall comm_delay
    ldi	cnt, 0x32
entropy_wait_loop:
    sbic	_SFR_IO_ADDR(PINB), 3
    rjmp entropy_received
    wdr
    rcall comm_delay
    dec	cnt
    brne entropy_wait_loop
    rjmp idle_wait
entropy_received:
    sbi	_SFR_IO_ADDR(PORTB), 4
    rcall comm_rx_state
    rcall comm_rx_byte
    mov	s4, temp
    rcall comm_rx_byte
    mov	s5, temp
    rcall comm_delay
    cbi	_SFR_IO_ADDR(PORTB), 4
    ldi	temp, 0x80
    sts	0x61, temp
    ldi	temp, 0x00
    sts	0x61, temp
    ldi	temp, KEY_2_01
    eor	s0, temp
    ldi	temp, KEY_2_02
    eor	s1, temp
    ldi	temp, KEY_2_03
    eor	s2, temp
    ldi	temp, KEY_2_04
    eor	s3, temp
    ldi	temp, KEY_2_05
    eor	s4, temp
    ldi	temp, AUTH_ROT_1_01
    eor	s5, temp
    ldi	temp, AUTH_ROT_1_02
    ldi	temp, 0x32
    mov	loop_ext, temp
entropy_outer_loop:
    wdr
    ldi	temp, 0x03
    mov	loop_int, temp
entropy_rotate_loop:
    clc
    ror	s0
    ror	s1
    ror	s2
    ror	s3
    ror	s4
    ror	s5
    brcc entropy_rotate_done
    ori	s0, 0x80
entropy_rotate_done:
    dec	loop_int
    brne entropy_rotate_loop
    mov	temp, s0
    rcall crypto_lcg_step_2
    mov	s0, res
    mov	temp, s1
    rcall crypto_lcg_step_2
    mov	s1, res
    mov	temp, s2
    rcall crypto_lcg_step_2
    mov	s2, res
    mov	temp, s3
    rcall crypto_lcg_step_2
    mov	s3, res
    mov	temp, s4
    rcall crypto_lcg_step_2
    mov	s4, res
    mov	temp, s5
    rcall crypto_lcg_step_2
    mov	s5, res
    dec	loop_ext
    brne entropy_outer_loop
    ldi	temp, KEY_1_01
    eor	s0, temp
    ldi	temp, KEY_1_02
    eor	s1, temp
    ldi	temp, KEY_1_03
    eor	s2, temp
    ldi	temp, KEY_1_04
    eor	s3, temp
    ldi	temp, KEY_1_05
    eor	s4, temp
    ldi	temp, AUTH_1_01
    eor	s5, temp
    ldi	temp, AUTH_1_02
    ldi	temp, 0x80
    sts	0x61, temp
    ldi	temp, 0x03
    sts	0x61, temp
    wdr
    cp	ent0, s0
    brne cmd_auth_write_done
    cp	ent1, s1
    brne cmd_auth_write_done
    cp	ent2, s2
    brne cmd_auth_write_done
    cp	ent3, s3
    brne cmd_auth_write_done
    out	_SFR_IO_ADDR(EEDR), s5
    cpi	s4, 0x40
    brcc cmd_auth_write_done
    out	0x22, zero
    out	0x21, s4
    sbi	_SFR_IO_ADDR(EECR), 2
    sbi	_SFR_IO_ADDR(EECR), 1
eeprom_write_final_wait:
    sbic	_SFR_IO_ADDR(EECR), 1
    rjmp eeprom_write_final_wait
cmd_auth_write_done:
    rjmp idle_wait
