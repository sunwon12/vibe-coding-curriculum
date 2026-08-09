---
name: knowledge-base
description: 내 지식베이스 관리 도우미 — 노트 추가·검색·지도 갱신·복습. 이 저장소 루트에서 동작한다.
triggers: ["kb", "지식", "지식베이스", "knowledge", "kb add", "kb search", "노트", "복습"]
argument-hint: "<operation> [args] — add | search | index | review | list | read"
---

# Knowledge Base (내 지식베이스 도우미)

이 저장소(=지금 열려 있는 폴더)의 노트를 관리한다. 규칙은 항상 루트 `CLAUDE.md`를 따른다.
동작 전에 `index.md`를 먼저 읽어 전체 지도를 파악한다.

## 동작

### add — 노트 추가

```
kb add <제목>            (예: kb add 로그인은-일단-안-넣기로)
```

1. 어느 폴더에 둘지 정한다(`CLAUDE.md`의 폴더 규칙). 애매하면 주인에게 한 줄로 묻는다.
2. **같은 주제 노트가 이미 있으면 새로 만들지 말고 그 노트를 고친다**(병합 우선).
3. 파일명은 `<제목>.md`(서술형, 제목=주제). 맨 위에 frontmatter를 넣는다:

```yaml
---
title: "<제목>"
created: <오늘 날짜 YYYY-MM-DD>
tags: ["<주제 태그>"]
summary: "<한 줄 요약 — 검색 키>"
---
```

4. 본문은 `# <제목>`으로 시작. 원본은 10%만, 핵심은 한 문장으로.
5. 관련 노트가 있으면 `[[파일명]]`으로 링크.
6. **끝나면 그 폴더 `_index.md`와 루트 `index.md`에 한 줄 추가**(인덱스 동기화).

### search — 검색

```
kb search <키워드>
```

1. `index.md`로 전체 맵 파악 → 2. frontmatter `tags`·`summary` 매칭 → 3. 파일명·본문 grep →
4. 관련도순으로 요약 제시. 필요하면 관련 노트 본문을 읽어 종합 답변.

### index — 지도 갱신

```
kb index
```

모든 `.md`의 frontmatter(title·tags·summary)를 스캔해 각 폴더 `_index.md`와 루트 `index.md`의
폴더 지도·최근 노트 목록을 최신으로 다시 쓴다.

### review — 복습 (선택)

```
kb review
```

`review_date`가 오늘 이하인 노트를 찾아, **먼저 질문으로 기억을 확인한 뒤** 내용을 보여준다.
기억나면 간격 상향(7d→15d→30d→완료), 막히면 7d로 리셋하고 frontmatter를 갱신한다.

### list / read

```
kb list [폴더]      — 폴더(또는 전체) 노트 목록
kb read <제목>       — 특정 노트 읽기(유사 매칭)
```

## 지켜야 할 선 (Hard Constraints)

- 루트 `CLAUDE.md`의 위키 프로토콜을 항상 따른다(특히 **병합 우선**·**인덱스 동기화**).
- **1노트 = 1개념**, 파일명 = 주제.
- 개인정보·비밀번호는 노트에 넣지 않는다. 저장소는 비공개(private)로만 백업.
- 파일을 지우거나 크게 갈아엎기 전엔 주인에게 쉬운 말로 설명하고 동의를 받는다.
