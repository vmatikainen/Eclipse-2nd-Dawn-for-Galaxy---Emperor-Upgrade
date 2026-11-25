"""Talk to a running Tabletop Simulator through its External Editor API (localhost).

Usage (run from the repository root, with TTS running and a game loaded):
    python tools/tts_live.py push                 Save & Play: Global's script and XML from the mod
    python tools/tts_live.py push --guid 3d6d3a   ... and the scripts/XML of these objects too
    python tools/tts_live.py lua probe.lua        run Lua in Global, print what it print()s
    echo 'print(Turns.turn_color)' | python tools/tts_live.py lua -

push sends the scripts as they are in the built mod file (3844682665.json, so run
tools/rebuild_mod.py first). TTS then reloads the game **from its last save**, not from the
table as it is now: save in TTS first (Games -> Save) if the current table should be kept.
It only replaces scripts and UI XML: changes to objects in the mod JSON (positions, snap
points, new objects) still need loading the mod through Games -> Workshop.

lua runs a chunk in Global and prints its print() output and any error. Return values don't
come back. A probe that only reads is harmless; one that changes objects changes the game.

TTS listens on 127.0.0.1:39999 and answers by connecting to 127.0.0.1:39998, which this tool
listens on. The VS Code TTS extension uses the same port: close it (or its connection) first.
"""
import argparse
import json
import os
import socket
import sys
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from annotate_boards import DEFAULT_MOD, walk  # noqa: E402

TTS_PORT, LISTEN_PORT = 39999, 39998


def exchange(message, wait):
    """Send one message to TTS and collect its answers for `wait` seconds."""
    received = []
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('127.0.0.1', LISTEN_PORT))
    except OSError:
        sys.exit(f'port {LISTEN_PORT} is in use (is the VS Code TTS extension connected?)')
    server.listen(5)
    server.settimeout(0.5)

    def serve():
        end = time.time() + wait
        while time.time() < end:
            try:
                conn, _ = server.accept()
            except socket.timeout:
                continue
            data = b''
            conn.settimeout(1)
            try:
                while True:
                    chunk = conn.recv(65536)
                    if not chunk:
                        break
                    data += chunk
            except OSError:
                pass
            received.append(data.decode('utf-8', 'replace'))

    thread = threading.Thread(target=serve)
    thread.start()
    try:
        with socket.create_connection(('127.0.0.1', TTS_PORT), timeout=5) as conn:
            conn.sendall(json.dumps(message).encode('utf-8'))
    except OSError:
        sys.exit(f'TTS is not listening on port {TTS_PORT}: is it running with a game loaded?')
    thread.join()
    server.close()

    decoder = json.JSONDecoder()
    messages = []
    for text in received:
        pos = 0
        while pos < len(text):
            while pos < len(text) and text[pos].isspace():
                pos += 1
            if pos >= len(text):
                break
            value, pos = decoder.raw_decode(text, pos)
            messages.append(value)
    return messages


def report(messages):
    """Print TTS's answers; returns 1 if there was an error."""
    failed = 0
    for m in messages:
        kind = m.get('messageID')
        if kind == 1:
            print(f'loaded: TTS reloaded the game with {len(m.get("scriptStates", []))} scripts')
        elif kind == 2:
            print(m.get('message'))
        elif kind == 3:
            print('ERROR ' + str(m.get('errorMessagePrefix') or m.get('error')), file=sys.stderr)
            failed = 1
    return failed


def push(args):
    with open(args.mod, encoding='utf-8') as f:
        mod = json.load(f)
    states = [{'name': 'Global', 'guid': '-1', 'script': mod.get('LuaScript', ''), 'ui': mod.get('XmlUI', '')}]
    if args.guid:
        found = {obj.get('GUID'): obj for obj in walk(mod['ObjectStates'])}
        for guid in args.guid:
            obj = found.get(guid)
            if obj is None:
                sys.exit(f'no object {guid} in {args.mod}')
            states.append({'name': obj.get('Nickname') or obj.get('Name'), 'guid': guid,
                           'script': obj.get('LuaScript', ''), 'ui': obj.get('XmlUI', '')})
    messages = exchange({'messageID': 1, 'scriptStates': states}, args.wait)
    if not any(m.get('messageID') == 1 for m in messages):
        print('no reload confirmed by TTS', file=sys.stderr)
        return 1
    return report(messages)


def lua(args):
    script = sys.stdin.read() if args.file == '-' else open(args.file, encoding='utf-8').read()
    return report(exchange({'messageID': 3, 'guid': '-1', 'script': script}, args.wait))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('push', help="Save & Play: send Global's script and XML (and --guid objects')")
    p.add_argument('--mod', default=DEFAULT_MOD, help='built mod JSON (default: %(default)s)')
    p.add_argument('--guid', action='append', help='also send this object (repeatable)')
    p.add_argument('--wait', type=float, default=10, help='seconds to collect output (default: %(default)s)')
    p.set_defaults(run=push)
    p = sub.add_parser('lua', help='run Lua in Global and print its print() output')
    p.add_argument('file', help="Lua file, or - for stdin")
    p.add_argument('--wait', type=float, default=6, help='seconds to collect output (default: %(default)s)')
    p.set_defaults(run=lua)
    args = parser.parse_args()
    sys.exit(args.run(args))


if __name__ == '__main__':
    main()
