# SIMT GPU Core

## Objective
I am trying to build a custom GPU inspired SIMT core running a minimal custom ISA. This project will include the assembler as well as the RTL for the SIMT core (and other things for verification). The SIMT core can run real parallel kernels with warp scheduling, divergence, and masked execution. 

## Architecture

The SIMT core will be 5 staged pipelined with N (to be determined) warps, a warp scheduler, and other units (will finish when microarchitecture is more concrete). 

## Potential Future Extensions

- FP32 Compatible
- Multiple Streaming Multiprocessors
- Simple Shared L2 Cache

