#!/usr/bin/env python3
"""Isolated Kitty Unicode-placeholder graphics reproduction.

This mirrors the pinned jupynvim `kitty_transmit_virtual` path without Neovim.
It only writes graphics escapes to an interactive terminal.
"""

from __future__ import annotations

import argparse
import base64
import binascii
import hashlib
import json
import os
import secrets
import sys
import termios
from pathlib import Path
from typing import Any


COLS = 48
DEFAULT_ROWS = 16
# Kitty maps the image ID through the placeholder foreground RGB. A per-run ID
# reduces collisions with other terminal clients; it is not a global registry.
IMAGE_ID = secrets.randbelow(0xFFFFFF) + 1
CHUNK_SIZE = 4096
PLACEHOLDER = "\U0010EEEE"
FIXTURE = Path(__file__).resolve().parents[1] / "fixtures" / "notebook-fidelity.ipynb"

# Exact Kitty placeholder-diacritics order used by pinned jupynvim image.lua.
DIACRITICS = (
    0x0305,0x030D,0x030E,0x0310,0x0312,0x033D,0x033E,0x033F,0x0346,0x034A,0x034B,0x034C,0x0350,0x0351,0x0352,0x0357,0x035B,0x0363,0x0364,0x0365,0x0366,0x0367,0x0368,0x0369,0x036A,0x036B,0x036C,0x036D,0x036E,0x036F,0x0483,0x0484,0x0485,0x0486,0x0487,0x0592,0x0593,0x0594,0x0595,0x0597,0x0598,0x0599,0x059C,0x059D,0x059E,0x059F,0x05A0,0x05A1,0x05A8,0x05A9,0x05AB,0x05AC,0x05AF,0x05C4,0x0610,0x0611,0x0612,0x0613,0x0614,0x0615,0x0616,0x0617,0x0657,0x0658,0x0659,0x065A,0x065B,0x065D,0x065E,0x06D6,0x06D7,0x06D8,0x06D9,0x06DA,0x06DB,0x06DC,0x06DF,0x06E0,0x06E1,0x06E2,0x06E4,0x06E7,0x06E8,0x06EB,0x06EC,0x0730,0x0732,0x0733,0x0735,0x0736,0x073A,0x073D,0x073F,0x0740,0x0741,0x0743,0x0745,0x0747,0x0749,0x074A,0x07EB,0x07EC,0x07ED,0x07EE,0x07EF,0x07F0,0x07F1,0x07F3,0x0816,0x0817,0x0818,0x0819,0x081B,0x081C,0x081D,0x081E,0x0823,0x0825,0x0826,0x0827,0x0829,0x082A,0x082B,0x082C,0x082D,0x0951,0x0953,0x0954,0x0F82,0x0F83,0x0F86,0x0F87,0x135D,0x135E,0x135F,0x17DD,0x193A,0x1A17,0x1A75,0x1A76,0x1A77,0x1A78,0x1A79,0x1A7A,0x1A7B,0x1A7C,0x1B6B,0x1B6D,0x1B6E,0x1B6F,0x1B70,0x1B71,0x1B72,0x1B73,0x1CD0,0x1CD1,0x1CD2,0x1CDA,0x1CDB,0x1CE0,0x1DC0,0x1DC1,0x1DC3,0x1DC4,0x1DC5,0x1DC6,0x1DC7,0x1DC8,0x1DC9,0x1DCB,0x1DCC,0x1DD1,0x1DD2,0x1DD3,0x1DD4,0x1DD5,0x1DD6,0x1DD7,0x1DD8,0x1DD9,0x1DDA,0x1DDB,0x1DDC,0x1DDD,0x1DDE,0x1DDF,0x1DE0,0x1DE1,0x1DE2,0x1DE3,0x1DE4,0x1DE5,0x1DE6,0x1DFE,0x20D0,0x20D1,0x20D4,0x20D5,0x20D6,0x20D7,0x20DB,0x20DC,0x20E1,0x20E7,0x20E9,0x20F0,0x2CEF,0x2CF0,0x2CF1,0x2DE0,0x2DE1,0x2DE2,0x2DE3,0x2DE4,0x2DE5,0x2DE6,0x2DE7,0x2DE8,0x2DE9,0x2DEA,0x2DEB,0x2DEC,0x2DED,0x2DEE,0x2DEF,0x2DF0,0x2DF1,0x2DF2,0x2DF3,0x2DF4,0x2DF5,0x2DF6,0x2DF7,0x2DF8,0x2DF9,0x2DFA,0x2DFB,0x2DFC,0x2DFD,0x2DFE,0x2DFF,0xA66F,0xA67C,0xA67D,0xA6F0,0xA6F1,0xA8E0,0xA8E1,0xA8E2,0xA8E3,0xA8E4,0xA8E5,0xA8E6,0xA8E7,0xA8E8,0xA8E9,0xA8EA,0xA8EB,0xA8EC,0xA8ED,0xA8EE,0xA8EF,0xA8F0,0xA8F1,0xAAB0,0xAAB2,0xAAB3,0xAAB7,0xAAB8,0xAABE,0xAABF,0xAAC1,0xFE20,0xFE21,0xFE22,0xFE23,0xFE24,0xFE25,0xFE26,0x10A0F,0x10A38,0x1D185,0x1D186,0x1D187,0x1D188,0x1D189,0x1D1AA,0x1D1AB,0x1D1AC,0x1D1AD,0x1D242,0x1D243,0x1D244,
)


def png_size(data: bytes) -> tuple[int, int]:
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("not a PNG with an IHDR chunk")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


def image_values(value: Any):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "image/png" and isinstance(child, str):
                yield child
            else:
                yield from image_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from image_values(child)


def fixture_png() -> bytes:
    notebook = json.loads(FIXTURE.read_text(encoding="utf-8"))
    for encoded in image_values(notebook):
        data = base64.b64decode(encoded, validate=True)
        if png_size(data) == (400, 200):
            return data
    raise ValueError(f"no 400x200 image/png value in {FIXTURE}")


def graphics_stream(png: bytes, rows: int) -> bytes:
    encoded = base64.b64encode(png).decode("ascii")
    parts: list[str] = []
    for offset in range(0, len(encoded), CHUNK_SIZE):
        chunk = encoded[offset : offset + CHUNK_SIZE]
        more = int(offset + CHUNK_SIZE < len(encoded))
        if offset == 0:
            parts.append(f"\x1b_Ga=t,f=100,i={IMAGE_ID},q=2,m={more};{chunk}\x1b\\")
        else:
            parts.append(f"\x1b_Gm={more},q=2;{chunk}\x1b\\")
    parts.append(f"\x1b_Ga=p,U=1,i={IMAGE_ID},p=1,c={COLS},r={rows},q=2\x1b\\")
    return "".join(parts).encode("ascii")


def tmux_wrap(data: bytes) -> bytes:
    return b"\x1bPtmux;" + data.replace(b"\x1b", b"\x1b\x1b") + b"\x1b\\"


def delete_stream() -> bytes:
    return f"\x1b_Ga=d,d=I,i={IMAGE_ID},q=2\x1b\\".encode("ascii")


def place_virtual_stream(rows: int) -> bytes:
    return (
        f"\x1b_Ga=d,d=i,i={IMAGE_ID},q=2\x1b\\"
        f"\x1b_Ga=p,U=1,i={IMAGE_ID},p=1,c={COLS},r={rows},q=2\x1b\\"
    ).encode("ascii")


def parsed_graphics_headers(stream: bytes) -> list[tuple[str, int]]:
    """Parse generated APC records while retaining only bounded header metadata."""
    text = stream.decode("ascii")
    records: list[tuple[str, int]] = []
    position = 0
    while position < len(text):
        if not text.startswith("\x1b_G", position):
            raise ValueError("generated stream contains a non-APC record")
        end = text.find("\x1b\\", position)
        if end < 0:
            raise ValueError("generated stream has an unterminated APC record")
        body = text[position + 3 : end]
        header, separator, payload = body.partition(";")
        if not separator:
            payload = ""
        records.append((header, len(payload)))
        position = end + 2
    return records


def placeholder_row(row: int) -> str:
    row_diacritic = chr(DIACRITICS[row])
    return "".join(PLACEHOLDER + row_diacritic + chr(DIACRITICS[col]) for col in range(COLS))


def write(data: bytes | str) -> None:
    raw = data.encode("utf-8") if isinstance(data, str) else data
    view = memoryview(raw)
    while view:
        written = os.write(sys.stdout.fileno(), view)
        view = view[written:]


def cursor(row: int, column: int = 1) -> str:
    return f"\x1b[{row};{column}H"


def clear_grid(top: int, rows: int) -> None:
    for row in range(top, top + rows):
        write(cursor(row) + "\x1b[2K")


def draw_grid(top: int, rows: int) -> None:
    rgb = ((IMAGE_ID >> 16) & 0xFF, (IMAGE_ID >> 8) & 0xFF, IMAGE_ID & 0xFF)
    for index in range(rows):
        write(cursor(top + index) + "\x1b[2K" + f"\x1b[38;2;{rgb[0]};{rgb[1]};{rgb[2]}m" + placeholder_row(index) + "\x1b[0m")


def status(row: int, message: str) -> None:
    write(cursor(row) + "\x1b[2K" + message)


def dump(png: bytes, rows: int, wrapped: bool) -> None:
    stream = graphics_stream(png, rows)
    records = parsed_graphics_headers(stream)
    encoded_length = len(base64.b64encode(png))
    chunks = len(records) - 1
    width, height = png_size(png)
    print(f"fixture={FIXTURE}")
    print(f"png={width}x{height} bytes={len(png)} sha256={hashlib.sha256(png).hexdigest()}")
    print(f"grid={COLS}x{rows} image_id={IMAGE_ID} fg=#{IMAGE_ID:06x}")
    print(f"transmit=base64_chars:{encoded_length} chunks:{chunks} chunk_limit:{CHUNK_SIZE}")
    print(f"parsed_records={len(records)} payload_chars={[size for _, size in records]}")
    print(f"first_header={records[0][0]}")
    print(f"placement={records[-1][0]}")
    print(f"stream_bytes={len(stream)} tmux_wrapped={'yes' if wrapped else 'no'}")
    print(f"reassert=a=d,d=i,i={IMAGE_ID},q=2 then a=p,U=1,i={IMAGE_ID},p=1,c={COLS},r={rows},q=2")
    print(f"delete=a=d,d=I,i={IMAGE_ID},q=2")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=int, default=DEFAULT_ROWS, help="placeholder rows (1-297; default: 16)")
    parser.add_argument("--dump", action="store_true", help="print bounded protocol metadata without terminal control output")
    args = parser.parse_args()
    if not 1 <= args.rows <= len(DIACRITICS):
        parser.error(f"--rows must be between 1 and {len(DIACRITICS)}")

    try:
        png = fixture_png()
    except (OSError, ValueError, json.JSONDecodeError, binascii.Error) as error:
        print(f"fixture error: {error}", file=sys.stderr)
        return 2

    in_tmux = bool(os.environ.get("TMUX")) and not bool(os.environ.get("JUPYNVIM_DISABLE_TMUX_PASSTHROUGH"))
    if args.dump:
        dump(png, args.rows, in_tmux)
        return 0
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        print("refusing graphics mode: stdin and stdout must both be interactive TTYs (use --dump for non-emitting diagnostics)", file=sys.stderr)
        return 2

    terminal = os.get_terminal_size(sys.stdout.fileno())
    top = 5
    needed_lines = top + args.rows + 1
    if terminal.columns < COLS or terminal.lines < needed_lines:
        print(f"refusing graphics mode: need at least {COLS} columns and {needed_lines} lines; have {terminal.columns}x{terminal.lines}", file=sys.stderr)
        return 2

    original_mode = termios.tcgetattr(sys.stdin.fileno())
    graphics = graphics_stream(png, args.rows)
    try:
        write("\x1b[?1049h\x1b[?25l\x1b[2J\x1b[H")
        status(1, f"Kitty Unicode-placeholder repro | fixture 400x200 | grid {COLS}x{args.rows}")
        status(2, f"id={IMAGE_ID} fg=#{IMAGE_ID:06x} | tmux DCS={'on' if in_tmux else 'off'} | terminal={terminal.columns}x{terminal.lines}")
        status(3, "s scroll; r redraw text; p reassert placement; c clear text; q quit (Ctrl-C restores)")
        write(tmux_wrap(graphics) if in_tmux else graphics)
        draw_grid(top, args.rows)
        status(top + args.rows + 1, "rendered: transmit + explicit virtual placement + per-cell placeholders")
        mode = termios.tcgetattr(sys.stdin.fileno())
        mode[3] &= ~(termios.ICANON | termios.ECHO)
        mode[6][termios.VMIN] = 1
        mode[6][termios.VTIME] = 0
        termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, mode)
        while True:
            key = os.read(sys.stdin.fileno(), 1)
            if not key:
                break
            if key in (b"q", b"Q", b"\x03"):
                break
            if key in (b"r", b"R"):
                clear_grid(top, args.rows)
                draw_grid(top, args.rows)
                status(top + args.rows + 1, "redraw: original placeholder text re-rendered; no graphics transmission")
            elif key in (b"s", b"S"):
                # Restrict LF scrolling to the grid: this moves terminal text, not a fresh draw.
                bottom = top + args.rows - 1
                write(f"\x1b[{top};{bottom}r" + cursor(bottom) + "\n\x1b[r")
                status(top + args.rows + 1, "scroll: terminal scrolled the placeholder text region up one row")
            elif key in (b"p", b"P"):
                reassert = place_virtual_stream(args.rows)
                write(tmux_wrap(reassert) if in_tmux else reassert)
                status(top + args.rows + 1, "placement: reset only this image's placements, then reasserted p=1; no retransmission")
            elif key in (b"c", b"C"):
                clear_grid(top, args.rows)
                status(top + args.rows + 1, "clear: placeholder text removed; image data remains until exit cleanup")
            else:
                status(top + args.rows + 1, "unknown key: s scroll, r redraw, p placement reset, c clear text, q quit")
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, original_mode)
        cleanup = delete_stream()
        write(tmux_wrap(cleanup) if in_tmux else cleanup)
        write("\x1b[0m\x1b[?25h\x1b[?1049l")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
