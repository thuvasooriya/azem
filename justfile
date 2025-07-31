PORT := "8000"
WASM_FOLDER := "zig-out/bin/"
SERVER_COMMAND := "python3 -m http.server " + PORT + " -d " + WASM_FOLDER

help:
    just --list --list-heading ''

serve:
    pkill -f "{{ SERVER_COMMAND }}" || true
    {{ SERVER_COMMAND }} &> /dev/null &

kill:
    pkill -f "{{ SERVER_COMMAND }}" || true

update_dvui:
    cd deps/dvui && git checkout main && git pull
