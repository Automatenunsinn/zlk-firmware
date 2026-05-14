/* Key Definitions */
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
#else /* OLD_KEY */
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

/* Auth Definitions */
#ifdef NEW_KEY
  #define AUTH_1_01 0x89
  #define AUTH_1_02 0xED
  #define AUTH_1_03 0xC3
  #define AUTH_1_04 0xAD
  #define AUTH_1_05 0x8F
  #define AUTH_1_06 0x61
  #define AUTH_1_07 0x32
#else /* OLD_AUTH */
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
#else /* OLD_AUTH_ROT */
  #define AUTH_ROT_1_01 0x8E
  #define AUTH_ROT_1_02 0x65
  #define AUTH_ROT_1_03 0xE1
  #define AUTH_ROT_1_04 0xA3
  #define AUTH_ROT_1_05 0x74
  #define AUTH_ROT_1_06 0x33
#endif
