# Adapted from https://github.com/devplayer0/fyp/blob/master/app/perfgrade/gem5_config/common.py

from m5.objects import *

class CM4XBar(CoherentXBar):
    width = 16

    frontend_latency = 0
    forward_latency = 1
    response_latency = 0
    snoop_response_latency = 0

    header_latency = 0

# Simple ALU Instructions have a latency of 1
class FUMinorInt(MinorDefaultIntFU):
    opList = [ OpDesc(opClass='IntAlu', opLat=1) ]

# Complex ALU instructions have a variable latencies
class FUMinorIntMul(MinorDefaultIntMulFU):
    opList = [ OpDesc(opClass='IntMult', opLat=2) ]

class FUMinorIntDiv(MinorDefaultIntDivFU):
    opList = [ OpDesc(opClass='IntDiv', opLat=9) ]

# Load/Store Units
class FUMinorMem(MinorDefaultMemFU):
    opList = [ OpDesc(opClass='MemRead', opLat=1),
               OpDesc(opClass='MemWrite', opLat=1) ]

# Misc Unit
class FUMinorMisc(MinorDefaultMiscFU):
    opList = [ OpDesc(opClass='IprAccess', opLat=1),
               OpDesc(opClass='InstPrefetch', opLat=1) ]

# Functional Units for this CPU
class CM4MinorFUPool(MinorFUPool):
    funcUnits = [FUMinorInt(), FUMinorIntMul(), FUMinorIntDiv(), FUMinorMem(), FUMinorMisc()]

class CM4Minor(MinorCPU):
    executeFuncUnits = CM4MinorFUPool()