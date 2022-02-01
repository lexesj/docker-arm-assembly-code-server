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

# Simple ALU Instructions have a latency of 1
class FUInt(FUDesc):
    opList = [ OpDesc(opClass='IntAlu', opLat=1) ]
    count = 1

# Complex ALU instructions have a variable latencies
class FUIntMul(FUDesc):
    opList = [ OpDesc(opClass='IntMult', opLat=2) ]
    count = 1

class FUIntDiv(FUDesc):
    opList = [ OpDesc(opClass='IntDiv', opLat=9) ]
    count = 1

# Load/Store Units
class FUMem(FUDesc):
    opList = [ OpDesc(opClass='MemRead', opLat=2),
               OpDesc(opClass='MemWrite', opLat=2) ]
    count = 1

# Functional Units for this CPU
class CM4FUPool(FUPool):
    FUList = [FUInt(), FUIntMul(), FUIntDiv(), FUMem()]

#class CM4BP(BiModeBP):
#    globalPredictorSize = 512
#    globalCtrBits = 2
#    choicePredictorSize = 512
#    choiceCtrBits = 2
#    BTBEntries = 128
#    BTBTagSize = 18
#    RASSize = 16
#    instShiftAmt = 2

class CM4BP(LocalBP):
    localPredictorSize = 128

class CM4(DerivO3CPU):
    fuPool = CM4FUPool()
    branchPred = CM4BP()

def parse_range(r: str):
    start, size = r.split(':')
    return AddrRange(int(start, base=0), size=int(size, base=0))