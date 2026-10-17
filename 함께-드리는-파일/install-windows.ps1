# 「내 일을 아는 AI 만들기」 윈도우 설치 도우미
# 하는 일: Git · GitHub 연결 도구 · Node.js · Orca · AI 도구 하나 설치,
#          GitHub 로그인과 SSH 키 등록, 워크북 폴더 내려받기
# 이미 있는 것은 건너뜁니다. 시험만 해 보려면: install-windows.ps1 -DryRun
param(
  [switch]$DryRun,
  [string]$Ai = "",
  [string]$Gh = "",
  [string]$FakeMissing = ""    # 시험용: 없는 척할 것들 (예: "winget git gh node orca claude ghauth sshkey")
)
$ErrorActionPreference = "Continue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$RepoUrl = "https://github.com/sunwon12/vibe-coding-curriculum"
$Docs = [Environment]::GetFolderPath("MyDocuments")
if (-not $Docs) { $Docs = $HOME }
$Dest = Join-Path $Docs "vibe-coding-curriculum"
$Temp = [IO.Path]::GetTempPath()
$Log = Join-Path $HOME "ai-install-log.txt"    # 설치 기록. 실패하면 이 파일을 보내 주세요
$Done = New-Object System.Collections.ArrayList
$Todo = New-Object System.Collections.ArrayList
$Fake = @($FakeMissing -split "\s+" | Where-Object { $_ })

function Say($t)  { Write-Host ""; Write-Host $t -ForegroundColor Cyan }
function Note($t) { Write-Host "  $t" }
function Has($c)  { if ($Fake -contains $c) { return $false }; return [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Ok($t)   { [void]$Done.Add($t) }
function Left($t) { [void]$Todo.Add($t) }
function RefreshPath {
  $m = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $u = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$m;$u"
}
function Act($desc, [scriptblock]$block) {
  if ($DryRun) { Note "[시험] $desc"; return $true }
  try { & $block; return $true } catch { Note ("실패: " + $_.Exception.Message); return $false }
}
function WingetInstall($id) {
  return (Act "winget install --id $id" {
    winget install --id $id -e --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget 종료 코드 $LASTEXITCODE" }
  })
}
function LatestAsset($repo, $pattern) {
  $r = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing
  return ($r.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1).browser_download_url
}
function DownloadAndRun($url, $name) {
  $f = Join-Path $Temp $name
  Invoke-WebRequest $url -OutFile $f -UseBasicParsing
  if ($name -like "*.msi") { Start-Process msiexec.exe -ArgumentList "/i `"$f`"" -Wait } else { Start-Process $f -Wait }
}
function IsArm { return ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") }
function AiPresent {
  if ($Fake -contains $AiCmd) { return $false }
  if (Get-Command $AiCmd -ErrorAction SilentlyContinue) { return $true }
  foreach ($d in $AiDirs) { if ($d -and (Test-Path (Join-Path $d "$AiCmd.exe"))) { return $true } }
  return $false
}
# 공식 설치 프로그램은 끝에 "Start Codex now?"를 묻고, 스스로 exit 하기도 한다.
# 그래서 질문을 끄고(CODEX_NON_INTERACTIVE) 별도 PowerShell에서 실행한 뒤, 프로그램이 실제로 생겼는지로 판단한다.
function InstallAi {
  if ($DryRun) { Note "[시험] irm $AiUrl | iex"; return $true }
  $env:CODEX_NON_INTERACTIVE = "1"
  $exe = (Get-Process -Id $PID).Path
  Add-Content -Path $Log -Value ("`n=== " + (Get-Date) + " $AiName 설치 ===")
  try { & $exe -NoProfile -ExecutionPolicy Bypass -Command "irm $AiUrl | iex" 2>&1 | Tee-Object -FilePath $Log -Append }
  catch { Add-Content -Path $Log -Value $_.Exception.Message }
  RefreshPath
  return (AiPresent)
}
function GhLoggedIn { if ($Fake -contains "ghauth") { return $false }; gh auth status -h github.com 2>$null | Out-Null; return ($LASTEXITCODE -eq 0) }
function SshWorks {
  if ($Fake -contains "ghauth") { return $false }
  $out = (ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T git@github.com 2>&1 | Out-String)
  return ($out -match "successfully authenticated")
}
function FindPubKey {
  if ($Fake -contains "sshkey") { return $null }
  foreach ($n in @("id_ed25519.pub", "id_ecdsa.pub", "id_rsa.pub")) { $k = Join-Path (Join-Path $HOME ".ssh") $n; if (Test-Path $k) { return $k } }
  return $null
}

Say "내 일을 아는 AI 만들기 - 설치를 시작합니다"
Note "10~20분 걸립니다. '이 앱이 디바이스를 변경하도록 허용하시겠어요?' 창이 뜨면 [예]를 누르세요."
Note "설치 창이 따로 뜨면 [Next]나 [설치]를 눌러 끝까지 진행하세요."

Say "1/8  어떤 AI를 쓰시나요?"
Note "1) Claude Code  - Claude를 결제했거나 익숙한 분"
Note "2) Codex CLI    - ChatGPT를 결제했거나 익숙한 분"
if ($Ai) { $choice = $Ai } else { $choice = Read-Host "  번호를 누르고 Enter (기본 1)" }
$localBin = Join-Path $HOME ".local\bin"
if ($choice -eq "2") { $AiName = "Codex CLI"; $AiCmd = "codex"; $AiUrl = "https://chatgpt.com/codex/install.ps1"; $AiDirs = @((Join-Path ([string]$env:LOCALAPPDATA) "Programs\OpenAI\Codex\bin"), $localBin) }
else { $AiName = "Claude Code"; $AiCmd = "claude"; $AiUrl = "https://claude.ai/install.ps1"; $AiDirs = @($localBin) }
Note "-> $AiName 로 진행합니다."

Say "2/8  winget (윈도우의 프로그램 설치 도구)"
$UseWinget = Has winget
if ($UseWinget) { Note "이미 있습니다."; Ok "winget" }
else { Note "없습니다. 설치 파일을 직접 내려받는 방식으로 진행합니다." }

Say "3/8  Git"
if (Has git) { Note "이미 있습니다."; Ok "Git" }
else {
  $ok = $false
  if ($UseWinget) { $ok = WingetInstall "Git.Git" }
  if (-not $ok -or (-not $DryRun -and -not $UseWinget)) {
    $ok = Act "Git for Windows 설치 파일을 받아 실행" { DownloadAndRun (LatestAsset "git-for-windows/git" "^Git-.*-64-bit\.exe$") "git-setup.exe" }
  }
  RefreshPath
  if ($ok) { Ok "Git" } else { Left "Git 설치 - 책 5장의 Git 명령을 직접 실행" }
}

Say "4/8  GitHub 연결 도구(gh)와 Node.js"
if (Has gh) { Ok "GitHub 연결 도구(gh)" }
else {
  $ok = $false
  if ($UseWinget) { $ok = WingetInstall "GitHub.cli" }
  if (-not $ok) {
    if (IsArm) { $pat = "windows_arm64\.msi$" } else { $pat = "windows_amd64\.msi$" }
    $ok = Act "gh 설치 파일(msi)을 받아 실행" { DownloadAndRun (LatestAsset "cli/cli" $pat) "gh-setup.msi" }
  }
  RefreshPath
  if ($ok) { Ok "GitHub 연결 도구(gh)" } else { Left "gh 설치 - 책 5장의 'GitHub 연결 도구' 명령을 직접 실행" }
}
if ((Has node) -and (Has npm)) { Ok "Node.js" }
else {
  $ok = $false
  if ($UseWinget) { $ok = WingetInstall "OpenJS.NodeJS.LTS" }
  if (-not $ok) {
    $ok = Act "Node.js LTS 설치 파일(msi)을 받아 실행" {
      $v = ((Invoke-RestMethod "https://nodejs.org/dist/index.json" -UseBasicParsing) | Where-Object { $_.lts } | Select-Object -First 1).version
      if (IsArm) { $arch = "arm64" } else { $arch = "x64" }
      DownloadAndRun "https://nodejs.org/dist/$v/node-$v-$arch.msi" "node-setup.msi"
    }
  }
  RefreshPath
  if ($ok) { Ok "Node.js" } else { Left "Node.js 설치 - 책 5장의 'Node.js' 명령을 직접 실행 (5걸음에서 필요)" }
}

Say "5/8  Orca (작업 화면)"
$orcaExe = Join-Path ([string]$env:LOCALAPPDATA) "Programs\Orca\Orca.exe"
if (($Fake -notcontains "orca") -and $env:LOCALAPPDATA -and (Test-Path $orcaExe)) { Note "이미 있습니다."; Ok "Orca" }
else {
  $ok = Act "Orca 설치 파일을 받아 실행" { DownloadAndRun "https://github.com/stablyai/orca/releases/latest/download/orca-windows-setup.exe" "orca-windows-setup.exe" }
  if ($ok) { Ok "Orca" }
  else {
    Act "다운로드 페이지 열기" { Start-Process "https://onorca.dev/download" } | Out-Null
    Left "열린 페이지에서 Orca를 내려받아 설치"
  }
}

Say "6/8  $AiName"
if (AiPresent) { Note "이미 있습니다."; Ok $AiName }
else {
  if (InstallAi) { Ok $AiName }
  else {
    Note "설치 기록의 마지막 부분:"
    if (Test-Path $Log) { Get-Content $Log -Tail 5 | ForEach-Object { Note "  $_" } }
    Left "$AiName 설치 실패 - 책 5장의 명령을 직접 실행 (기록: $Log)"
  }
}
if (-not $DryRun -and -not (Get-Command $AiCmd -ErrorAction SilentlyContinue)) {
  foreach ($d in $AiDirs) {
    if ($d -and (Test-Path (Join-Path $d "$AiCmd.exe"))) {
      $u = [Environment]::GetEnvironmentVariable("Path", "User")
      if ($u -notlike "*$d*") { [Environment]::SetEnvironmentVariable("Path", "$u;$d", "User") }
      RefreshPath
      Note "PowerShell이 $AiCmd 를 찾도록 경로를 등록했습니다."
    }
  }
}

Say "7/8  GitHub 연결 (로그인과 SSH 키 등록)"
if (-not ((Has gh) -or ($DryRun -and ($Fake -contains "gh")))) { Left "GitHub 연결 - gh를 설치한 뒤 이 파일을 다시 실행" }
elseif (-not ((Has ssh) -and (Has ssh-keygen))) { Left "GitHub 연결 - 윈도우 설정 > 앱 > 선택적 기능에서 'OpenSSH 클라이언트'를 추가한 뒤 다시 실행" }
elseif ((GhLoggedIn) -and (SshWorks)) { Note "이미 연결돼 있습니다."; Ok "GitHub 연결(SSH)" }
else {
  Note "GitHub 계정이 필요합니다."
  Note "1) 계정이 있다 - 지금 연결합니다"
  Note "2) 아직 없다 - 가입 페이지를 엽니다"
  Note "3) 나중에 한다"
  if ($Gh) { $ghc = $Gh } else { $ghc = Read-Host "  번호를 누르고 Enter (기본 1)" }
  if ($ghc -eq "2") {
    Act "가입 페이지 열기" { Start-Process "https://github.com/signup" } | Out-Null
    Left "GitHub에 가입한 뒤 이 파일을 다시 실행"
  }
  elseif ($ghc -eq "3") { Left "GitHub 연결 - 책 6장을 보고 직접 하거나 이 파일을 다시 실행" }
  else {
    $key = FindPubKey
    if (-not $key) {
      Note "이 컴퓨터의 SSH 키(GitHub에 보여 줄 열쇠)를 만듭니다."
      $sshDir = Join-Path $HOME ".ssh"; $priv = Join-Path $sshDir "id_ed25519"
      Act "ssh-keygen -t ed25519 (비밀번호 없이) -> $priv" {
        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
        # 빈 비밀번호("")가 그대로 전달되도록 명령줄을 통째로 넘긴다
        Start-Process ssh-keygen -ArgumentList ('-q -t ed25519 -N "" -f "' + $priv + '" -C "' + $env:USERNAME + '@' + $env:COMPUTERNAME + '"') -Wait -NoNewWindow
      } | Out-Null
      $key = "$priv.pub"
    } else { Note "이미 있는 SSH 키를 씁니다: $key" }
    if (-not (GhLoggedIn)) {
      Note "화면에 8자리 코드가 나옵니다. Enter를 누르면 브라우저가 열리고, 거기에 코드를 입력합니다."
      Act "gh auth login -h github.com -p ssh -s admin:public_key -w --skip-ssh-key" { gh auth login -h github.com -p ssh -s admin:public_key -w --skip-ssh-key } | Out-Null
    } elseif (-not $DryRun) {
      gh ssh-key list 2>$null | Out-Null
      if ($LASTEXITCODE -ne 0) {
        Note "SSH 키를 등록할 권한을 추가로 받습니다. 브라우저에서 한 번 더 승인하세요."
        gh auth refresh -h github.com -s admin:public_key
      }
    }
    Act "gh ssh-key add $key" { gh ssh-key add $key -t "$env:COMPUTERNAME (설치 도우미)" } | Out-Null
    if ($DryRun -or (SshWorks)) { Ok "GitHub 연결(SSH)" } else { Left "GitHub 연결 확인 실패 - 책 6장의 명령을 직접 실행" }
  }
}

Say "8/8  워크북 폴더"
$ForkSrc = "sunwon12/vibe-coding-curriculum"
function CloneOriginal {
  $ok = $false
  if ((Has git) -or $DryRun) {
    $ok = Act "git clone $RepoUrl $Dest" { git clone $RepoUrl $Dest; if ($LASTEXITCODE -ne 0) { throw "git 종료 코드 $LASTEXITCODE" } }
  }
  if ($ok) { return $true }
  return (Act "ZIP으로 내려받아 압축 풀기" {
    $zip = Join-Path $Temp "workbook.zip"; $tmp = Join-Path $Temp "workbook-unzip"
    Invoke-WebRequest "$RepoUrl/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive $zip -DestinationPath $tmp
    Move-Item (Join-Path $tmp "vibe-coding-curriculum-main") $Dest
  })
}
function ForkAndClone {
  Note "내 GitHub 계정에 워크북 사본(fork)을 만들고 내려받습니다."
  if ($DryRun) {
    Note "[시험] gh repo fork $ForkSrc --clone=false --default-branch-only"
    Note "[시험] gh repo clone <내아이디>/vibe-coding-curriculum $Dest"
    return $true
  }
  gh repo fork $ForkSrc --clone=false --default-branch-only
  if ($LASTEXITCODE -ne 0) { return $false }
  $me = (gh api user --jq .login)
  if (-not $me) { return $false }
  foreach ($n in 1..6) {          # fork가 만들어지는 데 몇 초 걸린다
    gh repo clone "$me/vibe-coding-curriculum" $Dest
    if ($LASTEXITCODE -eq 0) { return $true }
    Start-Sleep -Seconds 4
  }
  return $false
}
$ghReady = ((Has gh) -or ($DryRun -and ($Fake -contains "gh"))) -and (GhLoggedIn)
if (Test-Path (Join-Path $Dest "AGENTS.md")) {
  Note "이미 있습니다: $Dest"; Ok "워크북 폴더"
  if ($ghReady -and -not $DryRun) {
    $origin = (git -C $Dest remote get-url origin 2>$null)
    if ($origin -match [regex]::Escape($ForkSrc)) {
      Note "원본을 그대로 받은 폴더입니다. 내 GitHub에 fork를 만들어 연결합니다."
      Push-Location $Dest; gh repo fork --remote; $rc = $LASTEXITCODE; Pop-Location
      if ($rc -eq 0) { Ok "워크북 fork 연결" } else { Left "워크북 fork - 책 5장의 '워크북 폴더' 명령을 직접 실행" }
    }
  }
}
elseif ($ghReady) {
  if (ForkAndClone) { Ok "워크북 폴더(fork)" }
  elseif (CloneOriginal) { Ok "워크북 폴더"; Left "워크북 fork 실패 - 이 파일을 다시 실행하면 다시 시도합니다" }
  else { Left "워크북 폴더 - 책 5장의 '워크북 폴더' 명령을 직접 실행" }
}
else {
  if (CloneOriginal) { Ok "워크북 폴더"; Left "GitHub에 연결한 뒤 이 파일을 다시 실행하면 워크북을 내 계정으로 fork합니다" }
  else { Left "워크북 폴더 - 책 5장의 '워크북 폴더' 명령을 직접 실행" }
}

Say "끝났습니다"
foreach ($d in $Done) { Note "[완료] $d" }
foreach ($t in $Todo) { Note "[남음] $t" }
Say "이제 직접 하실 일 두 가지"
Note "1) PowerShell을 새로 열고 $AiCmd 를 입력한 뒤 Enter -> 책 6장을 보며 로그인"
Note "2) Orca를 열고 Add Repo -> 아래 폴더 선택 -> 폴더 옆 + 로 $AiName 실행 -> 책 8장의 첫 문장 붙여넣기"
Note "   $Dest"
if (-not $DryRun -and (Test-Path $Dest)) { Start-Process (Split-Path $Dest) }
