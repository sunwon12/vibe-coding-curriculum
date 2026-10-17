#!/bin/bash
# 「내 일을 아는 AI 만들기」 맥 설치 도우미
# 하는 일: Git · Homebrew · Orca · GitHub 연결 도구 · Node.js · AI 도구 하나 설치,
#          GitHub 로그인과 SSH 키 등록, 워크북 폴더 내려받기
# 이미 있는 것은 건너뜁니다. 시험만 해 보려면: bash install-mac.command --dry-run

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1
REPO_URL="https://github.com/sunwon12/vibe-coding-curriculum"
DEST="${WORKBOOK_DIR:-$HOME/Documents/vibe-coding-curriculum}"
FAKE_MISSING="${FAKE_MISSING:-}"     # 시험용: 없는 척할 것들 (예: "brew gh node orca claude ghauth sshkey")
LOG="$HOME/ai-install-log.txt"       # 설치 기록. 실패하면 이 파일을 보내 주세요
DONE=()
TODO=()

say()  { printf "\n\033[1m%s\033[0m\n" "$1"; }
note() { printf "  %s\n" "$1"; }
fake() { case " $FAKE_MISSING " in *" $1 "*) return 0 ;; esac; return 1; }
has()  { fake "$1" && return 1; command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY" = "1" ]; then printf "  [시험] %s\n" "$*"; return 0; fi; "$@"; }
run_sh() { if [ "$DRY" = "1" ]; then printf "  [시험] %s\n" "$1"; return 0; fi; bash -c "$1"; }

load_brew() {
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then
      eval "$("$b" shellenv)"
      [ "$DRY" = "1" ] || grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null || echo "eval \"\$($b shellenv)\"" >> "$HOME/.zprofile"
      return 0
    fi
  done
  return 1
}

ai_present() { fake "$AI_CMD" && [ "$DRY" = "1" ] && return 1; command -v "$AI_CMD" >/dev/null 2>&1 || [ -x "$HOME/.local/bin/$AI_CMD" ]; }

# 공식 설치 프로그램은 끝에 "Start Codex now?"를 묻고, 거기서 실행한 Codex를 닫으면 오류 코드가 돌아온다.
# 그래서 질문을 끄고(CODEX_NON_INTERACTIVE), 성공 여부는 프로그램이 실제로 생겼는지로 판단한다.
install_ai() {
  if [ "$DRY" = "1" ]; then printf "  [시험] %s\n" "$AI_INSTALL"; return 0; fi
  { echo; echo "=== $(date) $AI_NAME 설치 ==="; } >> "$LOG"
  env -u CODEX_HOME CODEX_NON_INTERACTIVE=1 bash -c "$AI_INSTALL" 2>&1 | tee -a "$LOG"
  ai_present
}

gh_logged_in() { fake ghauth && return 1; gh auth status -h github.com >/dev/null 2>&1; }
ssh_works()    { fake ghauth && return 1; ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T git@github.com 2>&1 | grep -q "successfully authenticated"; }
find_pubkey()  { fake sshkey && return 1; for k in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub" "$HOME/.ssh/id_rsa.pub"; do [ -f "$k" ] && { echo "$k"; return 0; }; done; return 1; }

install_orca_dmg() {
  local arch=x64 tmp mp rc
  [ "$(uname -m)" = "arm64" ] && arch=arm64
  tmp="$(mktemp -d)"
  curl -fL --progress-bar -o "$tmp/orca.dmg" "https://github.com/stablyai/orca/releases/latest/download/orca-macos-$arch.dmg" || return 1
  mp="$(hdiutil attach -nobrowse -readonly "$tmp/orca.dmg" | tail -1 | awk -F'\t' '{print $NF}')"
  [ -d "$mp/Orca.app" ] || return 1
  cp -R "$mp/Orca.app" /Applications/; rc=$?
  hdiutil detach "$mp" -quiet
  return $rc
}

clear 2>/dev/null
say "내 일을 아는 AI 만들기 — 설치를 시작합니다"
note "10~20분 걸립니다. 맥 비밀번호를 물으면 입력하세요(글자가 안 보여도 정상입니다)."

# 1. AI 고르기
say "1/8  어떤 AI를 쓰시나요?"
note "1) Claude Code  — Claude를 결제했거나 익숙한 분"
note "2) Codex CLI    — ChatGPT를 결제했거나 익숙한 분"
if [ -n "${AI_CHOICE:-}" ]; then CHOICE="$AI_CHOICE"; else read -r -p "  번호를 누르고 Enter (기본 1): " CHOICE; fi
case "$CHOICE" in
  2) AI_NAME="Codex CLI";   AI_CMD="codex";  AI_INSTALL="curl -fsSL https://chatgpt.com/codex/install.sh | sh" ;;
  *) AI_NAME="Claude Code"; AI_CMD="claude"; AI_INSTALL="curl -fsSL https://claude.ai/install.sh | bash" ;;
esac
note "→ $AI_NAME 로 진행합니다."

# 2. Git
say "2/8  Git"
if ! fake git && xcode-select -p >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
  note "이미 있습니다."; DONE+=("Git")
else
  note "맥이 '명령어 라인 개발자 도구' 설치 창을 띄웁니다. [설치]를 누르세요."
  run xcode-select --install
  note "설치가 끝나면 이 파일을 한 번 더 실행하세요."
  TODO+=("Git 설치 창에서 [설치]를 누른 뒤 이 파일을 다시 실행")
  [ "$DRY" = "1" ] || { read -r -p "  Enter를 누르면 닫힙니다."; exit 0; }
fi

# 3. Homebrew
say "3/8  Homebrew (프로그램을 설치해 주는 도구)"
load_brew >/dev/null 2>&1
if has brew; then
  note "이미 있습니다."; DONE+=("Homebrew")
else
  note "없어서 설치합니다. 5~10분 걸립니다."
  note "'Press RETURN/ENTER to continue'가 나오면 Enter, 'Password:'가 나오면 맥 비밀번호를 입력하세요."
  run_sh '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  if [ "$DRY" = "1" ] && [ "${FAKE_BREW_OK:-0}" = "1" ]; then FAKE_MISSING="${FAKE_MISSING/brew/}"; fi
  [ "$DRY" = "1" ] || load_brew
  if has brew; then DONE+=("Homebrew"); else TODO+=("Homebrew 설치 실패 — 책 5장의 Homebrew 명령을 직접 실행"); fi
fi

# 4. Orca
say "4/8  Orca (작업 화면)"
if ! fake orca && [ -d "/Applications/Orca.app" ]; then
  note "이미 있습니다."; DONE+=("Orca")
elif has brew && run brew install --cask stablyai/orca/orca; then
  DONE+=("Orca")
else
  note "설치 파일을 직접 내려받습니다(약 250MB)."
  if [ "$DRY" = "1" ]; then note "[시험] Orca DMG를 받아 Applications에 복사"; DONE+=("Orca")
  elif install_orca_dmg; then DONE+=("Orca")
  else run open "https://onorca.dev/download"; TODO+=("열린 페이지에서 Orca를 내려받아 설치"); fi
fi

# 5. GitHub 연결 도구와 Node.js
say "5/8  GitHub 연결 도구(gh)와 Node.js"
if has gh; then DONE+=("GitHub 연결 도구(gh)")
elif has brew && run brew install gh; then DONE+=("GitHub 연결 도구(gh)")
else TODO+=("gh 설치 — 책 5장의 'GitHub 연결 도구' 명령을 직접 실행"); fi
if has node && has npm; then DONE+=("Node.js")
elif has brew && run brew install node; then DONE+=("Node.js")
else TODO+=("Node.js 설치 — 책 5장의 'Node.js' 명령을 직접 실행 (5걸음에서 필요)"); fi

# 6. AI 도구
say "6/8  $AI_NAME"
if has "$AI_CMD" || { ! fake "$AI_CMD" && [ -x "$HOME/.local/bin/$AI_CMD" ]; }; then
  note "이미 있습니다."; DONE+=("$AI_NAME")
else
  if install_ai; then DONE+=("$AI_NAME")
  else
    note "설치 기록의 마지막 부분:"
    tail -5 "$LOG" 2>/dev/null | sed 's/^/    /'
    TODO+=("$AI_NAME 설치 실패 — 책 5장의 명령을 직접 실행 (기록: $LOG)")
  fi
fi
if [ "$DRY" != "1" ] && ! command -v "$AI_CMD" >/dev/null 2>&1 && [ -x "$HOME/.local/bin/$AI_CMD" ]; then
  grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  export PATH="$HOME/.local/bin:$PATH"
  note "터미널이 $AI_CMD 를 찾도록 경로를 등록했습니다."
fi

# 7. GitHub 로그인과 SSH 키 등록
say "7/8  GitHub 연결 (로그인과 SSH 키 등록)"
if ! has gh; then
  TODO+=("GitHub 연결 — gh를 설치한 뒤 이 파일을 다시 실행")
elif gh_logged_in && ssh_works; then
  note "이미 연결돼 있습니다."; DONE+=("GitHub 연결(SSH)")
else
  note "GitHub 계정이 필요합니다."
  note "1) 계정이 있다 — 지금 연결합니다"
  note "2) 아직 없다 — 가입 페이지를 엽니다"
  note "3) 나중에 한다"
  if [ -n "${GH_CHOICE:-}" ]; then GHC="$GH_CHOICE"; else read -r -p "  번호를 누르고 Enter (기본 1): " GHC; fi
  case "$GHC" in
    2) run open "https://github.com/signup"
       TODO+=("GitHub에 가입한 뒤 이 파일을 다시 실행") ;;
    3) TODO+=("GitHub 연결 — 책 6장을 보고 직접 하거나 이 파일을 다시 실행") ;;
    *) KEY="$(find_pubkey)"
       if [ -z "$KEY" ]; then
         note "이 컴퓨터의 SSH 키(GitHub에 보여 줄 열쇠)를 만듭니다."
         run mkdir -p "$HOME/.ssh"
         run ssh-keygen -q -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -C "$(whoami)@$(hostname -s)"
         KEY="$HOME/.ssh/id_ed25519.pub"
       else
         note "이미 있는 SSH 키를 씁니다: $KEY"
       fi
       if ! gh_logged_in; then
         note "화면에 8자리 코드가 나옵니다. Enter를 누르면 브라우저가 열리고, 거기에 코드를 입력합니다."
         run gh auth login -h github.com -p ssh -s admin:public_key -w --skip-ssh-key
       elif [ "$DRY" != "1" ] && ! gh ssh-key list >/dev/null 2>&1; then
         note "SSH 키를 등록할 권한을 추가로 받습니다. 브라우저에서 한 번 더 승인하세요."
         run gh auth refresh -h github.com -s admin:public_key
       fi
       run gh ssh-key add "$KEY" -t "$(hostname -s) (설치 도우미)" || note "(이미 등록된 키일 수 있습니다. 계속합니다.)"
       if [ "$DRY" = "1" ] || ssh_works; then DONE+=("GitHub 연결(SSH)")
       else TODO+=("GitHub 연결 확인 실패 — 책 6장의 명령을 직접 실행"); fi ;;
  esac
fi

# 8. 워크북 폴더 — 내 GitHub 계정으로 fork한 뒤 내려받는다
say "8/8  워크북 폴더"
FORK_SRC="sunwon12/vibe-coding-curriculum"
clone_original() {
  if run git clone "$REPO_URL" "$DEST"; then return 0; fi
  note "내려받기에 실패했습니다. ZIP으로 다시 시도합니다."
  TMP="$(mktemp -d)"
  run_sh "curl -fsSL '$REPO_URL/archive/refs/heads/main.zip' -o '$TMP/w.zip' && unzip -q '$TMP/w.zip' -d '$TMP' && mv '$TMP/vibe-coding-curriculum-main' '$DEST'"
}
fork_and_clone() {
  note "내 GitHub 계정에 워크북 사본(fork)을 만들고 내려받습니다."
  if [ "$DRY" = "1" ]; then
    printf "  [시험] gh repo fork %s --clone=false --default-branch-only\n" "$FORK_SRC"
    printf "  [시험] gh repo clone <내아이디>/vibe-coding-curriculum %s\n" "$DEST"
    return 0
  fi
  gh repo fork "$FORK_SRC" --clone=false --default-branch-only || return 1
  ME="$(gh api user --jq .login 2>/dev/null)"; [ -n "$ME" ] || return 1
  for n in 1 2 3 4 5 6; do          # fork가 만들어지는 데 몇 초 걸린다
    gh repo clone "$ME/vibe-coding-curriculum" "$DEST" && return 0
    sleep 4
  done
  return 1
}
if [ -f "$DEST/AGENTS.md" ]; then
  note "이미 있습니다: $DEST"; DONE+=("워크북 폴더")
  if has gh && gh_logged_in && git -C "$DEST" remote get-url origin 2>/dev/null | grep -q "$FORK_SRC"; then
    note "원본을 그대로 받은 폴더입니다. 내 GitHub에 fork를 만들어 연결합니다."
    if ( cd "$DEST" && run gh repo fork --remote ); then DONE+=("워크북 fork 연결"); else TODO+=("워크북 fork — 책 5장의 '워크북 폴더' 명령을 직접 실행"); fi
  fi
else
  run mkdir -p "$(dirname "$DEST")"
  if has gh && gh_logged_in; then
    if fork_and_clone; then DONE+=("워크북 폴더(fork)")
    elif clone_original; then DONE+=("워크북 폴더"); TODO+=("워크북 fork 실패 — 이 파일을 다시 실행하면 다시 시도합니다")
    else TODO+=("워크북 폴더 — 책 5장의 '워크북 폴더' 명령을 직접 실행"); fi
  else
    if clone_original; then DONE+=("워크북 폴더"); TODO+=("GitHub에 연결한 뒤 이 파일을 다시 실행하면 워크북을 내 계정으로 fork합니다")
    else TODO+=("워크북 폴더 — 책 5장의 '워크북 폴더' 명령을 직접 실행"); fi
  fi
fi

# 결과
say "끝났습니다"
for d in "${DONE[@]}"; do note "✅ $d"; done
for t in "${TODO[@]}"; do note "⬜ $t"; done
say "이제 직접 하실 일 두 가지"
note "① 터미널을 새로 열고 $AI_CMD 를 입력한 뒤 Enter → 책 6장을 보며 로그인"
note "② Orca를 열고 Add Repo → 아래 폴더 선택 → 폴더 옆 + 로 $AI_NAME 실행 → 책 8장의 첫 문장 붙여넣기"
note "   $DEST"
[ "$DRY" = "1" ] || { run open "$(dirname "$DEST")"; read -r -p "  Enter를 누르면 닫힙니다."; }
