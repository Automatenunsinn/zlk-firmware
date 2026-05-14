# ZLK Firmware

## Control Flow Diagram

```mermaid
flowchart TD
    Start([Start]) --> Reset["Reset & Initialize<br/>- Setup Stack & Registers<br/>- Configure Clock & Watchdog<br/>- Initialize I/O Ports"]
    Reset --> IdleWait["Idle Wait Loop<br/>- Accumulate Entropy<br/>- Wait for Command"]
    IdleWait --> CheckCmd{Command Received?}
    CheckCmd -->|0x31| Auth1["Authentication Step 1<br/>- Receive State<br/>- Load Crypto State from EEPROM<br/>- Apply Key 1<br/>- Perform Crypto Updates & Rotations<br/>- Apply Key 2<br/>- Transmit Result"]
    CheckCmd -->|0x32| Auth2["Authentication Step 2<br/>- Receive State<br/>- Receive Address<br/>- Load Crypto State from EEPROM<br/>- Apply Key 1<br/>- Perform Crypto Updates & Rotations<br/>- Apply Key 2<br/>- Transmit Result"]
    CheckCmd -->|0x33| AuthWrite["Authenticated Write<br/>- Transmit Accumulated Entropy<br/>- Receive Challenge<br/>- Decrypt Challenge<br/>- Verify Entropy Match"]
    CheckCmd -->|0x34| UpdateSN["Update Serial Number<br/>- Receive New Serial Number<br/>- Compare with Backup<br/>- Update EEPROM if Newer"]
    CheckCmd -->|0x35| WriteEEP["EEPROM Write<br/>- Receive Address & Data<br/>- Validate Address Range<br/>- Write to EEPROM"]
    CheckCmd -->|0x36| ReadEEP["EEPROM Read<br/>- Receive Address<br/>- Validate Address Range<br/>- Read from EEPROM<br/>- Transmit Result"]
    CheckCmd -->|Other| Invalid["Invalid Command"]
    
    Auth1 --> IdleWait
    Auth2 --> IdleWait
    
    AuthWrite --> ValidEnt{Entropy<br/>Match?}
    ValidEnt -->|Yes| WriteData["Write Data to EEPROM<br/>- Validate Address<br/>- Write Value"]
    ValidEnt -->|No| AuthWriteEnd["End Authentication"]
    WriteData --> AuthWriteEnd
    AuthWriteEnd --> IdleWait
    
    UpdateSN --> IdleWait
    WriteEEP --> IdleWait
    ReadEEP --> IdleWait
    Invalid --> IdleWait
```

## Overview

This AVR assembly firmware implements a authentication and write-protected memory access system with the following features:

- **Two-Stage Authentication**: Commands 0x31 and 0x32 provide two-stage cryptographic authentication
- **Authenticated Write**: Command 0x33 enables write access only after successful entropy-based authentication
- **Serial Number Management**: Command 0x34 manages versioned serial numbers with backup
- **EEPROM Access**: Commands 0x35 and 0x36 allow direct EEPROM read/write within protected address ranges
- **Cryptographic Operations**: Custom LCG-based crypto with state rotations and key application
- **Entropy Accumulation**: Continuous entropy collection for authentication challenges
