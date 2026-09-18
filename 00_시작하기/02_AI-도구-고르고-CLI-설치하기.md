---
title: "Orca와 AI 도구 설치하기"
type: 개발
tags: ["바이브코딩", "커리큘럼", "비개발자", "환경설정", "AI"]
created: 2026-07-20
updated: 2026-09-18
summary: "비개발자가 Orca를 공통 작업 화면으로 설치하고 Codex CLI나 Claude Code 하나를 연결해 로컬 폴더를 읽히는 운영체제별 준비 단계"
---

> 원문: [Orca 설치](https://www.onorca.dev/docs/install) · [Orca GitHub README](https://github.com/stablyai/orca/blob/main/README.md) · [Orca 첫 세션](https://www.onorca.dev/docs/first-session) · [OpenAI Codex CLI](https://developers.openai.com/codex/cli/) · [Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [Claude Code 터미널 가이드](https://code.claude.com/docs/en/terminal-guide) · [Claude Code CLAUDE.md](https://code.claude.com/docs/en/memory)
> 수집: 2026-09-18 · 확인 범위: Orca의 운영체제별 공식 배포 파일·첫 실행·저장소 연결, AI CLI 설치·로그인, 작업 폴더와 규칙 파일의 관계

# Orca와 AI 도구 설치하기

이 커리큘럼은 AI 스텝과 프로덕트 스텝 **모두 AI가 내 컴퓨터의 파일을 직접 읽고 고칠 수 있어야** 합니다. 비개발자가 파일·AI 대화·터미널·수정 내용을 여러 앱에서 찾아다니지 않도록 **Orca를 공통 작업 화면**으로 쓰고, 그 안에서 **Codex CLI 또는 Claude Code**를 실행합니다.

`⭐ 쉬움 · 약 20~30분 · 명령은 그대로 복사하거나 코치와 함께 실행`

## 결론: Orca 하나와 AI 하나를 준비하세요

처음에는 프로그램 역할을 둘로 나눕니다.

| 프로그램 | 하는 일 | 필수인가요? |
| --- | --- | --- |
| **Orca** | 폴더·Markdown·AI 대화·터미널·수정 비교를 한 창에서 보는 작업실 | 필수 |
| **Codex CLI 또는 Claude Code** | Orca 안에서 폴더를 읽고 파일을 만들거나 고치는 AI 작업자 | 둘 중 하나 필수 |

Orca는 AI 모델이 아니라 **AI가 일할 로컬 작업실**입니다. Codex·Claude는 실제로 생각하고 파일을 고치는
작업자입니다. 이 과정에서는 별도의 지식베이스 뷰어를 설치하지 않습니다. Markdown 지식베이스도 Orca에서
열고, 같은 화면에서 AI에게 읽고 고치게 합니다.

### AI는 둘 중 하나만 고르세요

| 이런 경우 | 먼저 고를 것 |
| --- | --- |
| ChatGPT·Codex를 이미 결제하거나 익숙하게 쓴다 | **Codex CLI** |
| Claude를 이미 결제하거나 익숙하게 쓴다 | **Claude Code** |
| 둘 다 처음이다 | 둘 중 가입이 편한 것 하나 |
| 둘 다 쓸 수 있지만 고민된다 | 같은 실제 작업을 10분씩 시킨 뒤 결과가 맞는 쪽 |

“지금 제일 똑똑한 AI”를 외워 고르지 않습니다. 체감 성능·가격·사용 한도는 계속 바뀌고, 두 도구 모두 이 과정에 충분합니다. **모델 순위보다 내 파일을 정확히 읽히고 필요한 맥락만 주는 방식**이 결과를 더 오래 좌우합니다.

## 왜 일반 채팅창 대신 Orca와 CLI인가요?

정확히 말하면 AI 모델의 계산은 일반 채팅과 CLI 모두 원격 서버에서 일어납니다. 차이는 **AI가 내 로컬 폴더와 도구에 연결되는 방식**입니다.

```mermaid
flowchart LR
  A["일반 채팅창"] --> B["내가 올린 파일만 봄"]
  C["Orca에서 연 프로젝트와 CLI"] --> D["그 폴더를 작업실로 삼음"]
  D --> E["파일 읽기·수정·명령 실행"]
```

- 일반 웹 채팅은 보통 내가 붙여넣거나 업로드한 자료만 봅니다.
- Orca에서 실행한 CLI는 **연 폴더를 현재 작업 공간**으로 삼아 파일을 읽고 고치며 필요한 명령도 실행할 수 있습니다.
- 어떤 데스크톱 앱은 로컬 프로젝트를 열 수 있으므로 “데스크톱은 전부 파일을 못 본다”는 뜻은 아닙니다. 이 과정에서 CLI를 기본으로 삼는 이유는 **작업 폴더가 명확하고 도구가 바뀌어도 같은 방식으로 쓸 수 있기 때문**입니다.

AI를 잘 쓰는 일의 큰 부분은 결국 파일 관리입니다. 여기서 파일 관리는 예쁘게 폴더를 정리한다는 뜻이 아니라 **무엇을 기록할지, 무엇을 빼둘지, 언제 어떤 문서를 읽힐지 정하는 컨텍스트 관리**입니다.

## 실행 위치가 AI의 첫 맥락을 정합니다

CLI에서 `codex`나 `claude`를 실행하기 전에 **먼저 작업할 폴더로 이동**합니다. 터미널을 연 위치가 아무
데나여도 되는 것이 아닙니다.

```mermaid
flowchart LR
  A["지식베이스 루트로 이동"] --> B["index.md·AGENTS.md 확인"]
  B --> C["codex 또는 claude 실행"]
  C --> D["이 프로젝트와 규칙에<br/>먼저 집중"]
  C -.-> E["다른 경로를 지정하고<br/>권한을 허용"]
  E --> F["컴퓨터의<br/>다른 폴더도 읽을 수 있음"]
```

- 실행 폴더는 **파일 접근의 절대적인 한계가 아니라 기본 관심사**입니다. 어느 폴더에서 실행했든 경로를
  정확히 알려 주고 앱·운영체제 권한이 허용하면 컴퓨터의 다른 폴더도 읽을 수 있습니다.
- 그래도 `index.md`와 `AGENTS.md` 또는 `CLAUDE.md`가 보이는 **프로젝트 루트**에서 시작하면 AI가 이 프로젝트에
  집중하고 해당 규칙을 자동으로 발견하기 쉬워집니다.
- Codex는 프로젝트 루트에서 현재 작업 폴더까지 `AGENTS.md`를 차례로 적용합니다. Claude Code는 현재 폴더와
  그 상위의 `CLAUDE.md`를 시작할 때 읽고, 하위 폴더의 규칙은 그 폴더의 파일을 읽을 때 추가로 불러옵니다.
- 홈 폴더처럼 너무 넓은 곳에서 시작하면 관계없는 맥락이 섞이고, 너무 깊은 하위 폴더에서 시작하면 전체 지도를
  놓칠 수 있으므로 루트에서 시작하는 습관이 좋습니다.

## 1. Orca 설치하기

Orca를 먼저 설치하되, **처음 실행은 AI 하나를 설치하고 로그인한 뒤** 합니다. 그러면 첫 실행 때 기존
Codex·Claude 설정을 가져오기 쉽습니다.

### 맥북

터미널을 열고 실행합니다.

```bash
brew install --cask stablyai/orca/orca
```

`brew: command not found`가 나오면 공식 다운로드 페이지를 엽니다.

```bash
open "https://onorca.dev/download"
```

### 윈도우 PowerShell

아래 명령은 Orca의 공식 GitHub 최신 윈도우 설치 파일을 임시 폴더에 받아 실행합니다.

```powershell
$installer = Join-Path $env:TEMP "orca-windows-setup.exe"
Invoke-WebRequest "https://github.com/stablyai/orca/releases/latest/download/orca-windows-setup.exe" -OutFile $installer
Start-Process $installer -Wait
```

다운로드가 막히면 공식 페이지를 엽니다.

```powershell
Start-Process "https://onorca.dev/download"
```

## 2. Orca 안에서 쓸 AI 하나 설치하기

### 맥북

터미널 앱을 열고, 앞에서 고른 AI **하나의 명령만** 실행합니다.

### 맥북 — Codex CLI를 골랐다면

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

설치 뒤 실행:

```bash
codex
```

### 맥북 — Claude Code를 골랐다면

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

설치 뒤 실행:

```bash
claude
```

### 윈도우

시작 메뉴에서 **PowerShell**을 열고, 앞에서 고른 AI **하나의 명령만** 실행합니다. 명령 프롬프트(CMD)가 아니라 PowerShell인지 확인합니다.

### 윈도우 — Codex CLI를 골랐다면

```powershell
irm https://chatgpt.com/codex/install.ps1 | iex
```

설치 뒤 실행:

```powershell
codex
```

### 윈도우 — Claude Code를 골랐다면

```powershell
irm https://claude.ai/install.ps1 | iex
```

설치 뒤 실행:

```powershell
claude
```

처음 실행하면 로그인 안내가 나옵니다. 사용하는 AI 계정으로 로그인합니다.

> 둘 다 설치할 필요는 없습니다. 설치 명령은 바뀔 수 있으므로 실패하면 위 공식 링크를 열거나 코치에게 **공식 문서의 최신 명령을 확인해 달라**고 합니다.

## 3. 로그인하고 Orca에 연결하기

설치한 AI를 일반 터미널에서 한 번 실행해 로그인합니다. 로그인까지 끝난 다음 Orca를 실행합니다.

```text
Codex를 골랐다면: codex
Claude를 골랐다면: claude
```

처음 실행한 Orca가 홈 폴더 접근을 물으면 허용하고, 발견한 Codex·Claude 설정을 가져옵니다. 그다음
**Add Repo**에서 `index.md`와 `AGENTS.md`가 있는 커리큘럼 폴더를 고릅니다. ZIP으로 받아 아직 Git 저장소가
아니라서 추가되지 않으면 [[03_GitHub로-체크포인트와-동기화-만들기]]를 먼저 끝내고 다시 추가합니다.

연결한 저장소 옆의 `+`를 누르고 설치한 **Codex** 또는 **Claude Code**를 고르면, Orca가 그 작업 폴더에서
AI를 실행합니다.

## 폴더 위치를 직접 확인하고 싶을 때

평소에는 Orca에서 저장소와 AI를 고르면 됩니다. 경로가 맞는지 확인해야 할 때만 Orca 안의 터미널에서 아래
명령을 씁니다.

### 맥북

Orca 터미널에서 `cd`와 한 칸을 먼저 입력한 뒤, Finder의 커리큘럼 폴더를 터미널에 끌어다 놓습니다. 경로가
붙으면 Enter를 누릅니다.

```bash
cd "/Users/내이름/Documents/바이브코딩-비개발자-커리큘럼"
pwd
ls index.md AGENTS.md
```

`pwd` 결과가 커리큘럼 폴더이고 `index.md`, `AGENTS.md` 두 파일이 보이면 맞게 들어온 것입니다.

### 윈도우 PowerShell

탐색기에서 커리큘럼 폴더를 `Shift + 오른쪽 클릭`하고 **경로로 복사**한 뒤 따옴표 안에 붙입니다.

```powershell
Set-Location "C:\Users\내이름\Documents\바이브코딩-비개발자-커리큘럼"
Get-Location
Get-Item .\index.md, .\AGENTS.md
```

### AI에게 첫 질문

도구가 열리면 아래 문장을 그대로 입력합니다.

```text
이 폴더의 AGENTS.md와 진행상태.md를 읽고,
이 커리큘럼이 무엇을 하는지와 지금 첫 할 일을 쉬운 말로 알려줘.
아직 파일은 수정하지 마.
```

AI가 실제 파일명을 근거로 답하면 연결된 것입니다. “파일을 첨부해 달라”고만 한다면 커리큘럼 폴더가 아닌 곳에서 실행했을 가능성이 큽니다.

## 완료 기준

- Orca를 설치했습니다.
- Codex CLI와 Claude Code 중 하나만 설치하고 로그인했습니다.
- Orca에서 커리큘럼 저장소를 열고 그 AI를 실행했습니다.
- AI가 `AGENTS.md`와 `진행상태.md`를 직접 읽어 답했습니다.
- Orca 파일 목록에서 `index.md`를 열어 확인했습니다.
- 어떤 AI가 영원히 최고라서가 아니라, **내 로컬 파일로 일할 수 있어서** 골랐다고 설명할 수 있습니다.

다음: 작업을 되돌리고 어디서든 이어 할 체크포인트 만들기 → [[03_GitHub로-체크포인트와-동기화-만들기]]
