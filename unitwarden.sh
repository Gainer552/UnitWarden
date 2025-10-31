#!/usr/bin/env bash
# unitwarden.sh — Comprehensive systemd unit & hidden unit detector
# by ChatGPT

set -euo pipefail

# === Colors ===
if [[ ${NO_COLOR:-0} -eq 1 ]]; then
  RESET=""; GREEN=""; YELLOW=""; MAGENTA=""; CYAN=""; RED=""; BOLD=""
else
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  MAGENTA=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  RED=$(tput setaf 1)
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
fi

# === Paths to search for hidden units ===
SEARCH_PATHS="${1:-/tmp:/opt:/home:/usr/local:/srv}"
IFS=':' read -r -a PATHS <<< "$SEARCH_PATHS"

echo -e "\n${BOLD}${CYAN}Systemd Units Overview${RESET}"
printf '%0.s-' {1..70}; echo

# === 1. Gather both static and dynamic units ===
# Merge unit files + loaded units to detect everything
mapfile -t UNITS < <(
  {
    systemctl list-unit-files --all --no-legend --no-pager 2>/dev/null
    systemctl list-units --all --no-legend --no-pager 2>/dev/null | awk '{print $1, $3}'
  } | awk '!seen[$1]++' | sort -u
)

# === 2. Display all known units with color codes ===
for line in "${UNITS[@]}"; do
  unit=$(awk '{print $1}' <<<"$line")
  state=$(awk '{print $2}' <<<"$line")
  load=$(systemctl show -p LoadState --value "$unit" 2>/dev/null || echo "-")
  active=$(systemctl show -p ActiveState --value "$unit" 2>/dev/null || echo "-")
  frag=$(systemctl show -p FragmentPath --value "$unit" 2>/dev/null || echo "")
  drops=$(systemctl show -p DropInPaths --value "$unit" 2>/dev/null || echo "")

  # color logic
  case "$state" in
    enabled*|active*) COLOR=$GREEN ;;
    disabled*|inactive*) COLOR=$YELLOW ;;
    masked*|failed*) COLOR=$MAGENTA ;;
    static*|indirect*|generated*|linked*) COLOR=$CYAN ;;
    *) COLOR=$CYAN ;;
  esac

  printf "%s%-50s%s %s(%s/%s)%s\n" "$COLOR" "$unit" "$RESET" "$CYAN" "$load" "$active" "$RESET"
  [[ -n "$frag" && "$frag" != "/" ]] && echo "    ${CYAN}Fragment:${RESET} $frag"
  [[ -n "$drops" && "$drops" != "[]" ]] && echo "    ${CYAN}Drop-ins:${RESET} $drops"
done

# === 3. Detect hidden unit files ===
echo -e "\n${BOLD}${CYAN}Hidden Unit Files${RESET}"
printf '%0.s-' {1..70}; echo

mapfile -t known_paths < <(systemctl show --all -p FragmentPath --value 2>/dev/null | grep -v '^$' | sort -u)
declare -A KNOWN
for p in "${known_paths[@]}"; do KNOWN["$p"]=1; done

hidden_found=0
for p in "${PATHS[@]}"; do
  [[ -d "$p" ]] || continue
  while IFS= read -r f; do
    # skip known fragment paths and standard dirs
    [[ ${KNOWN[$f]:-0} -eq 1 ]] && continue
    [[ "$f" =~ ^/(etc|usr|lib|run)/systemd/ ]] && continue
    ((hidden_found++))
    echo -e "${RED}Hidden:${RESET} $f"
    head -n 3 "$f" 2>/dev/null | sed 's/^/    /'
  done < <(find "$p" -maxdepth 5 -type f \( -name "*.service" -o -name "*.socket" -o -name "*.target" -o -name "*.timer" -o -name "*.mount" -o -name "*.slice" \) 2>/dev/null)
done
[[ $hidden_found -eq 0 ]] && echo -e "${GREEN}No hidden unit files found under:${RESET} $SEARCH_PATHS"

# === 4. Summary ===
echo -e "\n${BOLD}${CYAN}Summary${RESET}"
printf '%0.s-' {1..70}; echo
echo -e "${GREEN}Enabled/Active${RESET}, ${YELLOW}Disabled/Inactive${RESET}, ${MAGENTA}Masked/Failed${RESET}, ${CYAN}Static/Other${RESET}, ${RED}Hidden${RESET}"
echo -e "\nScanned paths for hidden units: ${CYAN}${SEARCH_PATHS}${RESET}"
echo -e "Use ${BOLD}systemctl daemon-reload${RESET} if new units don't appear in systemd's registry.\n"
