#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              CLOUDMASTER - Cloud Computing & Infrastructure Trainer          ║
# ║                     KEA Datamatiker Technology Exam                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── COLORS ────────────────────────────────────────────────────────────────────
R=$'\033[0;31m'   RED=$'\033[1;31m'
G=$'\033[0;32m'   GRN=$'\033[1;32m'
Y=$'\033[0;33m'   YLW=$'\033[1;33m'
B=$'\033[0;34m'   BLU=$'\033[1;34m'
M=$'\033[0;35m'   MAG=$'\033[1;35m'
C=$'\033[0;36m'   CYN=$'\033[1;36m'
W=$'\033[1;37m'   DIM=$'\033[2m'
RST=$'\033[0m'    BOLD=$'\033[1m'
BG_RED=$'\033[41m'  BG_GRN=$'\033[42m'  BG_YLW=$'\033[43m'

# Compatibility Aliases
GREEN=$GRN; YELLOW=$YLW; BLUE=$BLU; CYAN=$CYN; MAGENTA=$MAG; WHITE=$W; GRAY=$DIM; NC=$RST

# ─── SCORE TRACKING ────────────────────────────────────────────────────────────
SCORE=0
MAX_SCORE=0
CORRECT=0
WRONG=0
RETRIED=0
ZONE=0
PLAYER_NAME="Learner"
ZONE_SCORES=()
ZONE_MAX=()

declare -a QUESTION_HISTORY=()
CURRENT_Q_INDEX=0

# ─── PROGRESS FILE ─────────────────────────────────────────────────────────────
GAMEDIR="$HOME/.cloudmaster"
LABDIR="$GAMEDIR/lab"
LOGFILE="$GAMEDIR/session.log"
PROGRESS_FILE="$GAMEDIR/progress"
mkdir -p "$LABDIR"

save_progress() {
    echo "SCORE=$SCORE" > "$PROGRESS_FILE"
    echo "MAX_SCORE=$MAX_SCORE" >> "$PROGRESS_FILE"
    echo "LAST_ZONE=$1" >> "$PROGRESS_FILE"
    echo "DATE=$(date)" >> "$PROGRESS_FILE"
}

load_progress() {
    if [[ -f "$PROGRESS_FILE" ]]; then
        source "$PROGRESS_FILE"
        echo -e "${CYAN}Found previous session: Score $SCORE/$MAX_SCORE (Zone: $LAST_ZONE) — $DATE${NC}"
        echo -e "${YELLOW}Press [r] to resume from zone $LAST_ZONE, or any key for fresh start:${NC} "
        read -n1 choice
        echo
        if [[ "$choice" == "r" || "$choice" == "R" ]]; then
            ZONE=$LAST_ZONE
        else
            SCORE=0; MAX_SCORE=0
        fi
    fi
}

# ─── VISUAL HELPERS ────────────────────────────────────────────────────────────
sep()    { printf "\n  ${DIM}${C}%s${RST}\n" "-----------------------------------------------------------"; }
bigcap() { printf "  ${BOLD}${C}%s${RST}\n"  "==========================================================="; }
pause()  { echo; printf "  ${DIM}[ Press ENTER to continue ]${RST}"; read -r; }
press_enter() { pause; }
blank()  { echo; }

typeit() {
  local text="$1" delay="${2:-18}"
  local i char
  for (( i=0; i<${#text}; i++ )); do
    char="${text:$i:1}"
    printf "%s" "$char"
    sleep "0.0${delay}" 2>/dev/null || true
  done
  echo
}

pbar() {
  local cur="$1" max="$2" width="${3:-40}"
  [[ $max -le 0 ]] && max=1
  local filled=$(( (cur * width) / max ))
  local bar="" i
  for ((i=0; i<filled; i++));     do bar+="#"; done
  for ((i=filled; i<width; i++)); do bar+="-"; done
  local pct=$(( (cur * 100) / max ))
  printf "  [%s] %d%%\n" "$bar" "$pct"
}

section_header() {
  local name="$1"
  bigcap
  printf "  ${BOLD}${CYN}%s${RST}\n" "$name"
  bigcap; blank
}

# ─── FEEDBACK BOXES ────────────────────────────────────────────────────────────
teach() {
  blank
  printf "  ${BOLD}${BLU}+--[ TEACHING MOMENT ]%s+${RST}\n" "--------------------------------------"
  for line in "$@"; do
    printf "  ${BLU}|${RST}  %-56s  ${BLU}|${RST}\n" "$line"
  done
  printf "  ${BOLD}${BLU}+%s+${RST}\n" "-------------------------------------------------------------"
}

tip()           { echo "  ${BOLD}${YLW}[TIP]${RST}${YLW} ${1}${RST}"; }
correct_box()   { echo "  ${BOLD}${BG_GRN}  CORRECT  ${RST}${GRN}  ${1:-}${RST}"; }
wrong_box()     { echo "  ${BOLD}${BG_RED}  WRONG    ${RST}${R}  ${1}${RST}"; }
answer_reveal() { echo "  ${BOLD}${CYN}  -> Correct answer:${RST}${W} ${1}${RST}"; }
lab_pass()      { echo "  ${BOLD}${BG_GRN}  LAB PASS ${RST}${GRN}  ${1:-File verified.}${RST}"; }
lab_fail()      { echo "  ${BOLD}${BG_RED}  LAB FAIL ${RST}${R}  ${1}${RST}"; }

lab_header() {
  blank; sep
  printf "  ${BOLD}${MAG}[ LAB ] %s${RST}\n" "$1"
  printf "  ${DIM}%s${RST}\n" "${2:-Practical Exercise}"
  printf "  ${DIM}Working directory: ${W}$LABDIR${RST}\n"
  sep; blank
}

# ─── SCORE HELPERS ─────────────────────────────────────────────────────────────
LAB_TASKS=0
LAB_CORRECT=0
_award() {
  local p="$1"
  SCORE=$((SCORE + p)); MAX_SCORE=$((MAX_SCORE + p)); CORRECT=$((CORRECT + 1))
  printf "  ${GRN}${BOLD}+%d pts${RST}\n" "$p"
}

_miss() {
  local p="$1"
  MAX_SCORE=$((MAX_SCORE + p)); WRONG=$((WRONG + 1))
  printf "  ${RED}${BOLD}+0 pts${RST}\n"
}

_half() {
  local p="$1" half
  half=$(( p / 2 )); [[ $half -lt 1 ]] && half=1
  SCORE=$((SCORE + half)); MAX_SCORE=$((MAX_SCORE + p)); RETRIED=$((RETRIED + 1))
  printf "  ${YLW}${BOLD}+%d pts${RST}${YLW} (half credit -- correct on retry)${RST}\n" "$half"
}

# ─── CORE GAME ENGINE ──────────────────────────────────────────────────────────
ask_mc() {
  local q="$1"
  local oa="$2" ob="$3" oc="$4" od="$5"
  local correct="${6^^}" pts="$7"
  local wa="$8" wb="$9" wc="${10}" wd="${11}"
  local teaching="${12:-}" memtip="${13:-}"

  local score_before="$SCORE" max_before="$MAX_SCORE" correct_before="$CORRECT" wrong_before="$WRONG" retried_before="$RETRIED"
  QUESTION_HISTORY+=("${score_before}|${max_before}|${correct_before}|${wrong_before}|${retried_before}|${pts}")

  blank
  echo -e "  ${CYAN}${BOLD}Q: ${q}${RST}"
  blank
  echo -e "  ${YLW}A)${RST} $oa"
  echo -e "  ${YLW}B)${RST} $ob"
  echo -e "  ${YLW}C)${RST} $oc"
  echo -e "  ${YLW}D)${RST} $od"
  blank

  local ans ans2
  while true; do
    printf "  ${CYN}Your answer [A/B/C/D]: ${RST}"
    read -rsn1 ans

    if [[ "$ans" == $'\x0e' ]]; then
      echo; printf "  ${YLW}[SKIPPED - Mark as correct]${RST}\n"
      correct_box; _award "$pts"; return 0
    elif [[ "$ans" == $'\x02' ]]; then
      echo; printf "  ${YLW}[UNDO - Question reset]${RST}\n"
      SCORE="$score_before"; MAX_SCORE="$max_before"; CORRECT="$correct_before"
      WRONG="$wrong_before"; RETRIED="$retried_before"
      unset 'QUESTION_HISTORY[-1]'; QUESTION_HISTORY=("${QUESTION_HISTORY[@]}")
      return 0
    fi

    ans="${ans^^}"
    case "$ans" in A|B|C|D) break ;; esac
    echo; echo -e "  ${RED}  Please type A, B, C or D${RST}"
  done

  echo
  printf "  ${DIM}You chose: %s${RST}\n" "$ans"

  if [[ "$ans" == "$correct" ]]; then
    correct_box "The answer is $correct."; _award "$pts"; return
  fi

  local why_theirs
  case "$ans" in
    A) why_theirs="$wa" ;; B) why_theirs="$wb" ;;
    C) why_theirs="$wc" ;; D) why_theirs="$wd" ;;
  esac
  wrong_box "${why_theirs:-That option is incorrect.}"

  local correct_text
  case "$correct" in
    A) correct_text="A) $oa" ;; B) correct_text="B) $ob" ;;
    C) correct_text="C) $oc" ;; D) correct_text="D) $od" ;;
  esac

  answer_reveal "$correct_text"
  _miss "$pts"

  if [[ -n "$teaching" ]]; then
    IFS='|' read -ra tlines <<< "$teaching"
    teach "${tlines[@]}"
  fi
  [[ -n "$memtip" ]] && tip "$memtip"
}

ask_typed() {
  local q="$1" expected="$2" pts="$3"
  local retry_hint="${4:-}" model="${5:-}"
  local teaching="${6:-}" memtip="${7:-}" mode="${8:-contains}"

  local score_before="$SCORE" max_before="$MAX_SCORE" correct_before="$CORRECT" wrong_before="$WRONG" retried_before="$RETRIED"
  QUESTION_HISTORY+=("${score_before}|${max_before}|${correct_before}|${wrong_before}|${retried_before}|${pts}")

  blank; echo -e "  ${CYAN}${BOLD}Q: ${q}${RST}"
  printf "  ${CYN}> ${RST}"

  read -rsn1 ans_first
  if [[ "$ans_first" == $'\x0e' ]]; then
    echo; printf "  ${YLW}[SKIPPED - Mark as correct]${RST}\n"
    correct_box; _award "$pts"; return 0
  elif [[ "$ans_first" == $'\x02' ]]; then
    echo; printf "  ${YLW}[UNDO - Question reset]${RST}\n"
    SCORE="$score_before"; MAX_SCORE="$max_before"; CORRECT="$correct_before"
    WRONG="$wrong_before"; RETRIED="$retried_before"
    unset 'QUESTION_HISTORY[-1]'; QUESTION_HISTORY=("${QUESTION_HISTORY[@]}")
    return 0
  fi

  printf "%s" "$ans_first"
  local ans ans2
  read -r ans_rest
  ans="${ans_first}${ans_rest}"
  ans="$(echo "$ans" | xargs 2>/dev/null || echo "$ans")"

  _typed_match() {
    local a="${1,,}" e="${2,,}"
    if [[ "$mode" == "contains" ]]; then echo "$a" | grep -qiF "$e"
    else [[ "$a" == "$e" ]]; fi
  }

  if _typed_match "$ans" "$expected"; then
    correct_box "Key concept present: '$expected'"; _award "$pts"; return
  fi

  echo -e "  ${RED}  Not quite.${RST}  ${DIM}Hint: ${retry_hint}${RST}"
  blank
  printf "  ${YLW}  [RETRY] One more try for half points > ${RST}"; read -r ans2
  ans2="$(echo "$ans2" | xargs 2>/dev/null || echo "$ans2")"

  if _typed_match "$ans2" "$expected"; then
    correct_box "Correct on retry!"; _half "$pts"; return
  fi

  wrong_box "Still not right. Moving on."
  answer_reveal "${model:-$expected}"; _miss "$pts"
  
  if [[ -n "$teaching" ]]; then
    IFS='|' read -ra tlines <<< "$teaching"; teach "${tlines[@]}"
  fi
  [[ -n "$memtip" ]] && tip "$memtip"
}

do_task() {
  local instr="$1" check="$2" pts="$3"
  local solution="${4:-}" explanation="${5:-}"

  LAB_TASKS=$((LAB_TASKS + 1))

  local score_before="$SCORE" max_before="$MAX_SCORE" correct_before="$CORRECT" wrong_before="$WRONG" retried_before="$RETRIED"
  QUESTION_HISTORY+=("${score_before}|${max_before}|${correct_before}|${wrong_before}|${retried_before}|${pts}")

  blank
  printf "  ${MAG}${BOLD}[ TASK ]${RST} ${W}%s${RST}\n" "$instr"
  blank
  printf "  ${DIM}-> Do this in your lab terminal (cd $LABDIR)${RST}\n"
  printf "  ${DIM}-> When done, press ENTER here to verify.${RST}\n"

  local input
  read -rsn1 input

  if [[ "$input" == $'\x0e' ]]; then
    echo; printf "  ${YLW}[SKIPPED - Mark as correct]${RST}\n"
    lab_pass "Task accepted."; _award "$pts"; LAB_CORRECT=$((LAB_CORRECT + 1))
    return 0
  elif [[ "$input" == $'\x02' ]]; then
    echo; printf "  ${YLW}[UNDO - Task reset]${RST}\n"
    SCORE="$score_before"; MAX_SCORE="$max_before"; CORRECT="$correct_before"
    WRONG="$wrong_before"; RETRIED="$retried_before"; LAB_TASKS=$((LAB_TASKS - 1))
    unset 'QUESTION_HISTORY[-1]'; QUESTION_HISTORY=("${QUESTION_HISTORY[@]}")
    return 0
  fi

  # Run check in LABDIR context
  if (cd "$LABDIR" && eval "$check" &>/dev/null 2>&1); then
    lab_pass; _award "$pts"; LAB_CORRECT=$((LAB_CORRECT + 1)); return
  fi

  blank
  printf "  ${RED}${BOLD}  [x] Verification failed.${RST}\n"
  blank
  if [[ -n "$solution" ]]; then
    printf "  ${W}  Solution:${RST}\n"
    IFS='|' read -ra slines <<< "$solution"
    for sline in "${slines[@]}"; do
      printf "  ${BOLD}${CYN}    %s${RST}\n" "$sline"
    done
  fi
  [[ -n "$explanation" ]] && printf "\n  ${DIM}  Why: %s${RST}\n" "$explanation"
  blank
  printf "  ${YLW}  Make the fix now, then press ENTER for half points:${RST}\n"
  read -r

  if (cd "$LABDIR" && eval "$check" &>/dev/null 2>&1); then
    lab_pass "Correct after hint!"; _half "$pts"; LAB_CORRECT=$((LAB_CORRECT + 1)); return
  fi

  lab_fail "Still not verified. Moving on."; _miss "$pts"
}

setup_labs() {
    mkdir -p "$LABDIR"
    cat > "$LABDIR/README.md" << 'EOF'
# Cloud Sandbox
Follow the instructions in the main trainer.
Work in this directory to complete tasks.
EOF
}

setup_labs

# ─── ASCII HEADER ──────────────────────────────────────────────────────────────
show_header() {
    clear
    printf "${CYN}"
    cat << 'EOF'
                                          .-~~~-.
                                  .- ~ ~-(       )_ _
                                 /                    ~ -.
                                |                          ',
                                 \                         .'
                                   ~- ._ ,. ,.,.,., ,.. -~
                                           '       '
   ______   __         ______   __    __  _______   __       __   ______    ______   ________  ________  _______
  /      \ /  |       /      \ /  |  /  |/       \ /  \     /  | /      \  /      \ /        |/        |/       \
 /$$$$$$  |$$ |      /$$$$$$  |$$ |  $$ |$$$$$$$  |$$  \   /$$ |/$$$$$$  |/$$$$$$  |$$$$$$$$/ $$$$$$$$/ $$$$$$$  |
 $$ |  $$/ $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$$  \ /$$$ |$$ |__$$ |$$ \__$$/    $$ |   $$ |__    $$ |__$$ |
 $$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$$$  /$$$$ |$$    $$ |$$      \    $$ |   $$    |   $$    $$<
 $$ |   __ $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ $$ $$/$$ |$$$$$$$$ | $$$$$$  |   $$ |   $$$$$/    $$$$$$$  |
 $$ \__/  |$$ |_____ $$ \__$$ |$$ \__$$ |$$ |__$$ |$$ |$$$/ $$ |$$ |  $$ |/  \__$$ |   $$ |   $$ |_____ $$ |  $$ |
 $$    $$/ $$       |$$    $$/ $$    $$/ $$    $$/ $$ | $/  $$ |$$ |  $$ |$$    $$/    $$ |   $$       |$$ |  $$ |
  $$$$$$/  $$$$$$$$/  $$$$$$/   $$$$$$/  $$$$$$$/  $$/      $$/ $$/   $$/  $$$$$$/     $$/    $$$$$$$$/ $$/   $$/
EOF
    printf "${RST}"
    echo
    typeit "  Topic: Cloud Infrastructure, Security & Nginx" 10
    typeit "  Zones: 5 | Questions per zone: 4-5 | Scoring: exam-calibrated" 10
    echo
}

# ─── ZONE MENU ─────────────────────────────────────────────────────────────────
show_menu() {
    bigcap
    printf "  ${BOLD}${W}SELECT ZONE${RST}  |  ${DIM}Current Score: ${CYN}%d/%d${RST}\n" "$SCORE" "$MAX_SCORE"
    bigcap
    echo
    echo -e "  ${CYN}[1]${RST} Zone 1 — Cloud Models (IaaS, PaaS, SaaS)"
    echo -e "  ${CYN}[2]${RST} Zone 2 — Linux User Management & Sudo"
    echo -e "  ${CYN}[3]${RST} Zone 3 — SSH Security & Keys"
    echo -e "  ${CYN}[4]${RST} Zone 4 — Networking & Monitoring"
    echo -e "  ${CYN}[5]${RST} Zone 5 — Web Deployment (Nginx & TLS)"
    echo
    echo -e "  ${CYN}[9]${RST} Show score / grade estimate"
    echo -e "  ${CYN}[0]${RST} Exit"
    echo
    printf "  ${CYN}${BOLD}[ Press ENTER for FULL EXAM ]${RST}  or choice: "
}

# ══════════════════════════════════════════════════════════════════════════════
# ZONE 1: CLOUD MODELS
# ══════════════════════════════════════════════════════════════════════════════
zone1() {
    section_header "ZONE 1 — Cloud Models (IaaS, PaaS, SaaS)"
    local z_score=0
    local z_start=$SCORE

    echo -e "${GRAY}Understanding the shared responsibility model and service types.${NC}"
    echo
    press_enter

    ask_mc \
        "What does IaaS (Infrastructure as Code) provide primarily?" \
        "A fully managed application ready for users" \
        "A platform for developers to deploy code without managing servers" \
        "Virtual servers (VMs), storage, and networking where YOU manage the OS" \
        "A database that scales automatically" \
        "C" 2 \
        "A describes SaaS." \
        "B describes PaaS." \
        "CORRECT — IaaS gives you the 'bricks' (VMs) and you handle the OS and above." \
        "D is a specific managed service (DBaaS)."

    ask_mc \
        "Which of these is a key characteristic of PaaS (Platform as a Service)?" \
        "You are responsible for patching the Operating System" \
        "You only worry about the application code and data; the runtime is managed" \
        "It is always cheaper than IaaS" \
        "You must manage physical hardware" \
        "B" 2 \
        "A is IaaS — in PaaS, the cloud provider patches the OS." \
        "CORRECT — PaaS handles the runtime, middleware, and O/S." \
        "C is not necessarily true; it depends on usage." \
        "D is false for all cloud models."

    ask_typed \
        "What does SaaS stand for?" \
        "Software as a Service" 2 \
        "Think: Gmail, Office 365, Dropbox." \
        "Software as a Service" \
        "SaaS provides a complete product that is run and managed by the service provider."

    ask_mc \
        "In the shared responsibility model, who is responsible for data security in the cloud?" \
        "Only the Cloud Provider" \
        "Only the Customer" \
        "Both (Cloud Provider for 'of' the cloud, Customer for 'in' the cloud)" \
        "Nobody, it is handled by the internet" \
        "C" 2 \
        "A is wrong — the provider secure the infrastructure, not your data." \
        "B is wrong — the provider shares some responsibility for infrastructure security." \
        "CORRECT — Responsibility is shared." \
        "D is nonsense."

    ZONE_SCORES+=($((SCORE - z_start)))
    ZONE_MAX+=(8)
    save_progress 1
}

# ══════════════════════════════════════════════════════════════════════════════
# ZONE 2: LINUX USER MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════
zone2() {
    section_header "ZONE 2 — Linux User Management & Sudo"
    local z_start=$SCORE

    echo -e "${GRAY}Securing your cloud VM by avoiding the root user.${NC}"
    echo
    press_enter

    ask_mc \
        "Why is it generally avoided to log in and work directly as the 'root' user?" \
        "Because root is a slower user account" \
        "To prevent accidental system-breaking commands and limit impact of breaches" \
        "Because root cannot use SSH" \
        "Because root is not allowed to use the internet" \
        "B" 2 \
        "A is false; root is just a user with ID 0." \
        "CORRECT — root has absolute power; a mistake can be fatal, and a breached root session is game over." \
        "C is false; root can use SSH if configured (though discouraged)." \
        "D is false."

    ask_typed \
        "Which command do you use to create a new user in Linux?" \
        "adduser" 2 \
        "It's more user-friendly than useradd." \
        "adduser" \
        "adduser follows a script that prompts for password and details, making it easier than useradd."

    ask_mc \
        "What does the 'sudo' command allow a user to do?" \
        "Restart the computer" \
        "Execute a single command with superuser (root) privileges" \
        "Change their own password" \
        "Delete other users" \
        "B" 2 \
        "A is possible with sudo, but not its primary definition." \
        "CORRECT — 'superuser do' allows temporary escalation." \
        "C doesn't require sudo for your own password." \
        "D requires sudo, but it's not the ONLY thing it does."

    ask_typed \
        "Which special command is used to SAFELY edit the /etc/sudoers file?" \
        "visudo" 2 \
        "Think: vi + sudo." \
        "visudo" \
        "visudo checks the syntax before saving, preventing you from locking yourself out of sudo."

    lab_header "Adding a Sudoer" "Granting a user sudo privileges."
    do_task \
        "Create a file named 'sudoers_add' in the lab dir that contains the line to give user 'sshine' full sudo access without a password." \
        "grep -q \"sshine ALL=(ALL:ALL) NOPASSWD: ALL\" sudoers_add" \
        5 \
        "sshine ALL=(ALL:ALL) NOPASSWD: ALL" \
        "This line grants sshine the ability to run any command as any user without being prompted for a password."

    ZONE_SCORES+=($((SCORE - z_start)))
    ZONE_MAX+=(11)
    save_progress 2
}

# ══════════════════════════════════════════════════════════════════════════════
# ZONE 3: SSH SECURITY
# ══════════════════════════════════════════════════════════════════════════════
zone3() {
    section_header "ZONE 3 — SSH Security & Keys"
    local z_start=$SCORE

    echo -e "${GRAY}Passwordless entry and key management.${NC}"
    echo
    press_enter

    ask_mc \
        "Where does a Linux server store the public keys that are allowed to log in as a specific user?" \
        "~/.ssh/known_hosts" \
        "~/.ssh/authorized_keys" \
        "/etc/ssh/sshd_config" \
        "~/.ssh/id_rsa.pub" \
        "B" 2 \
        "A stores fingerprints of SERVERS you have visited." \
        "CORRECT — This file holds the public keys authorized for the user." \
        "C is the global SSH daemon configuration." \
        "D is YOUR public key on your client machine."

    ask_mc \
        "What is the correct permission (chmod) for the .ssh directory and the authorized_keys file?" \
        "777 (world readable/writable)" \
        "700 for .ssh/ and 600 for authorized_keys" \
        "644 for both" \
        "Permission doesn't matter for SSH" \
        "B" 2 \
        "A is a massive security risk; SSH will often ignore world-writable keys." \
        "CORRECT — Only the owner should be able to read/write these." \
        "C is too permissive (group/others can read)." \
        "D is false; SSH is very strict about permissions."

    ask_typed \
        "Which command is used to securely copy files from your local machine to a remote cloud VM?" \
        "scp" 2 \
        "Secure CoPy." \
        "scp" \
        "scp uses SSH for data transfer and provides the same authentication/security."

    ask_mc \
        "What happens during an SSH key exchange (Diffie-Hellman)?" \
        "The private key is sent to the server for verification" \
        "The public key is compared to a database of known passwords" \
        "A shared secret is established without ever sending the private key over the wire" \
        "The server sends its public key to be added to authorized_keys" \
        "C" 2 \
        "A is WRONG — private keys NEVER leave your machine." \
        "B is false; keys and passwords are different mechanisms." \
        "CORRECT — Cryptographic proof is provided without revealing the secret." \
        "D is the server identity process, but not the key exchange for login."

    lab_header "Securing the Keyhole" "Setting correct permissions."
    mkdir -p "$LABDIR/.ssh"
    touch "$LABDIR/.ssh/authorized_keys"
    do_task \
        "Set the permissions of the '.ssh' folder in the lab dir to 700 and the 'authorized_keys' file inside it to 600." \
        "[[ \$(stat -c %a .ssh) == \"700\" ]] && [[ \$(stat -c %a .ssh/authorized_keys) == \"600\" ]]" \
        5 \
        "chmod 700 .ssh && chmod 600 .ssh/authorized_keys" \
        "Strict permissions prevent other users on the system from tampering with your access."

    ZONE_SCORES+=($((SCORE - z_start)))
    ZONE_MAX+=(13)
    save_progress 3
}

# ══════════════════════════════════════════════════════════════════════════════
# ZONE 4: NETWORKING & MONITORING
# ══════════════════════════════════════════════════════════════════════════════
zone4() {
    section_header "ZONE 4 — Networking & Monitoring"
    local z_start=$SCORE

    echo -e "${GRAY}Watching the traffic and guarding the ports.${NC}"
    echo
    press_enter

    ask_mc \
        "What does the '-p' flag do in 'netstat -atlpn'?" \
        "Show only Public IP addresses" \
        "Show only Port numbers" \
        "Show the PID and name of the Program owning the connection" \
        "Enable Passphrase authentication" \
        "C" 2 \
        "A is false; -n shows numeric addresses." \
        "B is false." \
        "CORRECT — Very useful for identifying which process (e.g. nginx, sshd) is listening." \
        "D is nonsense."

    ask_mc \
        "If netstat shows a service listening on '0.0.0.0:80', what does it mean?" \
        "The service is only available on the local loopback" \
        "The service is listening on all available network interfaces on port 80" \
        "The service has no IP address assigned" \
        "The service is blocked by the firewall" \
        "B" 2 \
        "A would be 127.0.0.1:80." \
        "CORRECT — 0.0.0.0 represents all interfaces." \
        "C is false." \
        "D is false; netstat shows what the app is doing, not what the firewall is blocking."

    ask_typed \
        "What is the default port for SSH?" \
        "22" 2 \
        "It's the very first port most people open on a cloud VM." \
        "22" \
        "Port 22 is the standard for Secure Shell."

    ask_mc \
        "Why is it important to use a Cloud Firewall (Security Groups) in addition to OS-level firewalls?" \
        "It is faster than the OS firewall" \
        "It blocks traffic BEFORE it even reaches your virtual machine, saving resources and increasing security" \
        "It is required by law" \
        "It allows you to use more than 65535 ports" \
        "B" 2 \
        "A is negligible." \
        "CORRECT — Infrastructure firewalls act as a first line of defense." \
        "C is false." \
        "D is false; the port range is a TCP/IP limitation."

    ZONE_SCORES+=($((SCORE - z_start)))
    ZONE_MAX+=(8)
    save_progress 4
}

# ══════════════════════════════════════════════════════════════════════════════
# ZONE 5: WEB DEPLOYMENT (NGINX & TLS)
# ══════════════════════════════════════════════════════════════════════════════
zone5() {
    section_header "ZONE 5 — Web Deployment (Nginx & TLS)"
    local z_start=$SCORE

    echo -e "${GRAY}Serving content and securing it with certificates.${NC}"
    echo
    press_enter

    ask_mc \
        "Why should you ALWAYS run 'nginx -t' before reloading the Nginx service?" \
        "To speed up the reload process" \
        "To check the configuration for syntax errors and prevent the server from crashing" \
        "To update the TLS certificates automatically" \
        "To clear the web cache" \
        "B" 2 \
        "A is false." \
        "CORRECT — In production, a syntax error can take down your whole site. Always test first!" \
        "C is done via Certbot." \
        "D is false."

    ask_typed \
        "Which tool is most commonly used to automate getting free TLS/SSL certificates from Let's Encrypt?" \
        "certbot" 2 \
        "Think: Certificate + Robot." \
        "certbot" \
        "Certbot handles the challenge, download, and often the Nginx configuration automatically."

    ask_mc \
        "What does 'systemctl reload nginx' do differently than 'systemctl restart nginx'?" \
        "Restart is faster" \
        "Reload only applies configuration changes without dropping active connections" \
        "Restart is used for TLS/SSL changes only" \
        "Reload is only for static files" \
        "B" 2 \
        "A is false; Restart is usually slower as it stops and starts." \
        "CORRECT — Reload is graceful; it starts new workers and retires old ones after they finish current requests." \
        "C is false; both work, but reload is better." \
        "D is false."

    ask_mc \
        "What is the purpose of a 'Reverse Proxy' like Nginx?" \
        "To speed up the client's internet connection" \
        "To sit in front of an application server (like Spring Boot) and handle TLS, load balancing, or static files" \
        "To hide the existence of the website" \
        "To allow users to bypass the firewall" \
        "B" 2 \
        "A is false." \
        "CORRECT — Nginx is often the 'entry point' that forwards requests to backends." \
        "C is false." \
        "D is WRONG — proxies are often part of the security layer."

    lab_header "Nginx Health Check" "Testing configuration."
    cat > "$LABDIR/nginx.conf" << 'EOF'
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
}
EOF
    do_task \
        "The nginx.conf in the lab dir is missing a closing brace '}' at the end of the file. Fix it." \
        "grep -q \"}\" nginx.conf && [[ \$(tail -n1 nginx.conf) == \"}\" ]]" \
        5 \
        "echo \"}\" >> nginx.conf" \
        "Nginx configuration files use braces for blocks. Every open '{' must have a matching '}'."

    ZONE_SCORES+=($((SCORE - z_start)))
    ZONE_MAX+=(11)
    save_progress 5
}

# ─── FINAL SCORE ───────────────────────────────────────────────────────────────
show_score() {
    clear
    section_header "EXAM RESULTS"
    pbar "$SCORE" "$MAX_SCORE"
    blank
    printf "  Final Score: ${CYN}%d/%d${RST}\n" "$SCORE" "$MAX_SCORE"
    printf "  Questions:   ${GRN}%d Correct${RST} | ${RED}%d Wrong${RST} | ${YLW}%d Retried${RST}\n" "$CORRECT" "$WRONG" "$RETRIED"
    blank
    
    local pct=$(( (SCORE * 100) / (MAX_SCORE > 0 ? MAX_SCORE : 1) ))
    local grade="F"
    [[ $pct -ge 50 ]] && grade="E"
    [[ $pct -ge 60 ]] && grade="D"
    [[ $pct -ge 70 ]] && grade="C"
    [[ $pct -ge 85 ]] && grade="B"
    [[ $pct -ge 95 ]] && grade="A"

    printf "  Estimated Grade: ${BOLD}${CYN}%s${RST} (%d%%)\n" "$grade" "$pct"
    blank
    if [[ $pct -ge 80 ]]; then
        typeit "  Outstanding! You are ready for the Cloud exam." 10
    elif [[ $pct -ge 50 ]]; then
        typeit "  Good job. A bit more review on the weak spots and you'll be set." 10
    else
        typeit "  Keep practicing. Focus especially on the lab tasks and security concepts." 10
    fi
    blank
    press_enter
}

# ─── MAIN LOOP ─────────────────────────────────────────────────────────────────
main() {
    load_progress
    while true; do
        show_header
        show_menu
        read -r choice
        case "$choice" in
            1) zone1 ;;
            2) zone2 ;;
            3) zone3 ;;
            4) zone4 ;;
            5) zone5 ;;
            9) show_score ;;
            0) exit 0 ;;
            "") zone1; zone2; zone3; zone4; zone5; show_score; exit 0 ;;
            *) echo -e "  ${RED}Invalid choice${RST}"; sleep 1 ;;
        esac
    done
}

main
