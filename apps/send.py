#!/usr/bin/env python3
"""Send a BFLT binary to RP2350-MINI-A over the serial console and run it."""
import argparse
import serial
import time
import uu
import io
import sys


def encode_to_uue(data: bytes, name: str = "app") -> str:
    inbuf = io.BytesIO(data)
    outbuf = io.BytesIO()
    uu.encode(inbuf, outbuf, name=name, mode=0o755)
    return outbuf.getvalue().decode("ascii")


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
