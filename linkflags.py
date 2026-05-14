Import("env")
env.Append(LINKFLAGS=["-nostartfiles", "-nodefaultlibs", "-Wl,--entry=0x0", "-Wl,--undefined=main"])
