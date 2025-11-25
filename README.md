Author: Adam Salameh
Project Overview

This repository contains a complete SystemVerilog verification environment for a Frame Aligner (FA) design.
The environment is built using classes, mailboxes, interface-based connections, functional coverage, and multiple constrained-random and directed test modes.

The Verification Environment validates the FA’s ability to:
1. Detect legal headers (HEAD1 = AFAA, HEAD2 = BA55)

2. Reject illegal headers

3. Maintain correct fr_byte_position state machine

4. Identify frame boundaries

5. Avoid false triggers from payload patterns

6. Maintain robustness across random, aligned, loss-of-sync, and custom sequences

Components:
* Generator – produces random, legal, illegal, and custom edge-case frames

* Driver – serially feeds bytes into DUT

* Monitor_in – samples RX path

* Monitor_out – samples DUT output (fr_byte_position, frame_detect)

* Scoreboard – predicts expected behavior + checks correctness

* Reference Model (inside Scoreboard) – models the FA state machine

* Coverage – Header coverage + payload pattern coverage

Test Modes Implemented

✔ 1. RANDOM_FRAMES

Fully constrained-random:
Random header (HEAD1 / HEAD2 / ILLEGAL)
Random payload (size = 10 bytes)
Achieves wide functional exploration

✔ 2. LOSS_OF_SYNC

Creates conditions intended to force misalignment:
Continuous illegal headers
Junk data
Stress on realignment mechanism

✔ 3. ALIGNED

Stream of legal frames back-to-back to ensure:

Proper alignment maintenance
No misalignment under ideal conditions

✔ 4. CUSTOM (Directed Full Mode)

Custom Edge Cases

HEAD1 LSB correct, MSB wrong

HEAD2 MSB correct, LSB wrong

HEAD1 LSB + HEAD2 MSB

HEAD2 LSB + HEAD1 MSB

Payload contains HEAD1 (AFAA)

Payload contains HEAD1 reversed (AAAF)

Payload contains HEAD2 (BA55)

Payload contains HEAD2 reversed (55BA)

This mode guarantees full corner-case coverage of header detection and payload false-header immunity.


🐞 Bugs Found in DUT (Design Under Test)

  Issue #1 — Half-Valid Header Causes Incorrect In-Cycle Alignment

    When:

    LSB is legal (AA or 55),

    MSB is illegal,
    The design sets:

    fr_byte_position = 1 for one cycle
    then returns to 0

    This behavior is correct, but the DUT originally glitched under certain sequences until fixed.

  Issue #2 — Payload Contains Reversed Legal Header

    Case:

    Header is ILLEGAL

    Payload contains reversed legal header (e.g., AAAF)

    DUT incorrectly treated this as a new frame start.

    This was flagged by:
    Payload coverage
    Driver reverse-header injection
    Scoreboard mismatch detection
