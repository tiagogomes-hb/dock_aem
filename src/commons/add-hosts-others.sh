#!/usr/bin/env bash
#
# Add entries to /etc/hosts if they are not already present.
# Creates a timestamped backup before modifying the file.
# Usage examples:
#   # Add two entries (quoted as needed)
#   ./scripts/add-hosts.sh '127.0.0.1 example.local' '127.0.0.1 author.local'
#
#   # Read entries from a file (one entry per line, '#' lines ignored)
#   ./scripts/add-hosts.sh -f hosts-to-add.txt
#
#   # Dry-run: show what would be done
#   ./scripts/add-hosts.sh -n '127.0.0.1 example.local'
#
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
HOSTS_FILE="/etc/hosts"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [options] ["ip hostname [hostname2 ...]"]

Options:
  -f, --file PATH    Read entries from file (one per line). Lines starting with # are ignored.
  -n, --whatif       Dry-run; show actions without changing /etc/hosts.
  -h, --help         Show this help and exit.

Examples:
  $SCRIPT_NAME '127.0.0.1 example.local'
  $SCRIPT_NAME -f hosts-to-add.txt
  $SCRIPT_NAME -n -f hosts-to-add.txt
EOF
}

FROM_FILE=""
WHATIF=0
ENTRIES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            if [[ -z ${2-} ]]; then
                echo "Missing path for $1" >&2; exit 2
            fi
            FROM_FILE="$2"
            shift 2
            ;;
        -n|--whatif)
            WHATIF=1
            shift
            ;;
        -h|--help)
            usage; exit 0
            ;;
        --)
            shift; break
            ;;
        -* )
            echo "Unknown option: $1" >&2; usage; exit 2
            ;;
        *)
            ENTRIES+=("$1")
            shift
            ;;
    esac
done

if [[ -n "$FROM_FILE" ]]; then
    if [[ ! -f "$FROM_FILE" ]]; then
        echo "From-file '$FROM_FILE' not found." >&2; exit 3
    fi
    # read file, ignore blank lines and comments
    while IFS= read -r line || [[ -n $line ]]; do
        line_trim=$(printf '%s' "$line" | sed -e 's/^\s*//' -e 's/\s*$//')
        [[ -z "$line_trim" || "$line_trim" =~ ^# ]] && continue
        ENTRIES+=("$line_trim")
    done < "$FROM_FILE"
fi

if [[ ${#ENTRIES[@]} -eq 0 ]]; then
    echo "No entries provided. Nothing to do."
    exit 0
fi

do_backup() {
    local hosts="$1"
    if [[ ! -f "$hosts" ]]; then
        echo "Hosts file '$hosts' not found." >&2; exit 4
    fi
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    local bak="${hosts}.${ts}.bak"
    if [[ $WHATIF -eq 1 ]]; then
        echo "Would create backup: $bak"
    else
        if [[ $EUID -ne 0 ]]; then
            sudo cp -- "$hosts" "$bak"
        else
            cp -- "$hosts" "$bak"
        fi
        echo "Backup created: $bak"
    fi
}

ensure_entry() {
    local entry="$1"
    # Use grep -Fxq to match exact whole line
    if [[ $EUID -ne 0 ]]; then
        if sudo grep -Fxq -- "$entry" "$HOSTS_FILE" 2>/dev/null; then
            echo "Exists: $entry"
            return 0
        fi
    else
        if grep -Fxq -- "$entry" "$HOSTS_FILE" 2>/dev/null; then
            echo "Exists: $entry"
            return 0
        fi
    fi

    if [[ $WHATIF -eq 1 ]]; then
        echo "Would add: $entry"
        return 0
    fi

    if [[ $EUID -ne 0 ]]; then
        printf '%s\n' "$entry" | sudo tee -a "$HOSTS_FILE" > /dev/null
    else
        printf '%s\n' "$entry" >> "$HOSTS_FILE"
    fi
    echo "Added: $entry"
}

# Backup once before changes
do_backup "$HOSTS_FILE"

for e in "${ENTRIES[@]}"; do
    # trim whitespace
    e_trim=$(printf '%s' "$e" | sed -e 's/^\s*//' -e 's/\s*$//')
    [[ -z "$e_trim" ]] && continue
    ensure_entry "$e_trim"
done

echo "Done."
