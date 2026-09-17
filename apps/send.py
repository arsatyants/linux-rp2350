#!/usr/bin/env python3
"""Send a BFLT binary to RP2350-MINI-A over the serial console and run it."""
import argparse
import serial
import time
import binascii
import sys


def encode_to_uue(data: bytes, name: str = "app") -> str:
    # The stdlib `uu` module was removed in Python 3.13 (it was just a thin
    # wrapper around binascii.b2a_uu/a2b_uu, which are still present).
    lines = [f"begin 755 {name}"]
    for i in range(0, len(data), 45):
        chunk = data[i:i + 45]
        lines.append(binascii.b2a_uu(chunk).decode("ascii").rstrip("\n"))
    lines.append("`")
    lines.append("end")
    return "\n".join(lines) + "\n"


def send(port: str, baud: int, binary_path: str, run: bool = True):
    with open(binary_path, "rb") as f:
        payload = f.read()

    uue = encode_to_uue(payload, name="app").splitlines()

    with serial.Serial(port, baud, timeout=3) as s:
        s.dtr = False
        s.rts = False
        s.reset_input_buffer()

        # Break out of any leftover partial shell command.
        s.write(b"\x03\x03\n")
        time.sleep(0.2)
        s.read(1024)

        # Switch to writable directory and start decoder.
        for cmd in [b"cd /mnt/data\n", b"uudecode\n"]:
            s.write(cmd)
            time.sleep(0.2)
            s.read(1024)

        # Feed the uuencoded file.
        for line in uue:
            s.write((line + "\n").encode("ascii"))
            time.sleep(0.03)
        s.write(b"\n")
        time.sleep(1.5)
        s.read(8192)  # discard decode echoes

        if run:
            s.write(b"chmod +x app && ./app; echo EXIT:$?\n")
            time.sleep(1.0)
            out = s.read(4096).decode("utf-8", errors="replace")
            print(out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", help="BFLT binary to send")
    parser.add_argument("-p", "--port", default="/dev/ttyUSB0")
    parser.add_argument("-b", "--baud", type=int, default=115200)
    parser.add_argument("--no-run", action="store_true", help="only upload")
    args = parser.parse_args()

    send(args.port, args.baud, args.binary, run=not args.no_run)
