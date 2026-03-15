#!/usr/bin/env python3
import json
import os
import struct
import sys
import threading
import time

OUTPUT_PATH = os.environ.get("THORIUM_TABS_OUTPUT", "/tmp/thorium-tabs.json")
COMMAND_PATH = os.environ.get("THORIUM_TABS_COMMAND", "/tmp/thorium-tabs-command.json")
WRITE_LOCK = threading.Lock()
RUNNING = True


def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        return None
    message_length = struct.unpack("<I", raw_length)[0]
    payload = sys.stdin.buffer.read(message_length)
    if not payload:
        return None
    return json.loads(payload.decode("utf-8"))


def send_message(message):
    payload = json.dumps(message).encode("utf-8")
    with WRITE_LOCK:
        sys.stdout.buffer.write(struct.pack("<I", len(payload)))
        sys.stdout.buffer.write(payload)
        sys.stdout.buffer.flush()


def write_snapshot(message):
    directory = os.path.dirname(OUTPUT_PATH)
    if directory:
        os.makedirs(directory, exist_ok=True)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as handle:
        json.dump(message, handle)


def poll_commands():
    global RUNNING
    while RUNNING:
        if os.path.exists(COMMAND_PATH):
            try:
                with open(COMMAND_PATH, "r", encoding="utf-8") as handle:
                    command = json.load(handle)
                os.remove(COMMAND_PATH)
                send_message(command)
            except Exception as exc:
                send_message({"ok": False, "error": str(exc)})
        time.sleep(0.2)


def main():
    thread = threading.Thread(target=poll_commands, daemon=True)
    thread.start()

    global RUNNING
    while True:
        message = read_message()
        if message is None:
            break

        if message.get("type") == "tabs-snapshot":
            write_snapshot(message)
            send_message({"ok": True, "path": OUTPUT_PATH})
        else:
            send_message({"ok": False, "error": "unsupported message"})

    RUNNING = False
    thread.join(timeout=1)


if __name__ == "__main__":
    main()
