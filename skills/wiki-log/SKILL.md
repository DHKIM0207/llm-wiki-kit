---
name: wiki-log
description: Use when a coding-agent work session in any project produced something worth remembering in the LLM wiki — a recurring problem solved, an environment quirk discovered, a design decision made, or a long debugging detour. Also use when the user says "위키에 남겨줘", "기록해줘", or approves a proposal to record the session.
---

# 작업 기록 → 위키

## 볼트 찾기

1. 세션 컨텍스트의 `LLM 위키 볼트:` 줄(플러그인 SessionStart 훅이 주입하거나 CLAUDE.md에 있음) → 그 절대경로
2. 없으면 `~/.claude/llm-wiki/vault-path` 파일 첫 줄
3. 없으면 현재 디렉터리가 볼트인지 — 루트에 `AGENTS.md`(또는 `CLAUDE.md`)와 `wiki/index.md`
4. 모두 아니면 멈추고 `wiki-init`을 권한다

이하 `<VAULT>`는 그 절대경로다. 이 스킬은 주로 볼트 밖에서 호출된다 — **모든 경로를 절대경로로 쓴다.**

## 핵심 원칙

**어느 프로젝트에서 작업했든 기록은 한 곳에 모인다.**

## 남길 가치가 있는가 — 먼저 판단한다

| 남긴다 | 남기지 않는다 |
|---|---|
| 되풀이될 문제를 해결했다 | 단순 조회, 일회성 명령 |
| 이 환경만의 특성을 발견했다 | 이미 코드·문서에 있는 것 |
| 설계 결정을 내렸다 | git 이력이 이미 기록하는 것 |
| 삽질이 길었다 | 결론 없이 끝난 탐색 |

애매하면 **택하지 않은 대안과 그 이유**가 있는지 본다. 있으면 남길 값어치가 있다.

## 절차

### 1. 기록 파일 작성

`<VAULT>/wiki/sessions/YYYY-MM-DD-<제목>.md`

제목은 한글 그대로, 공백은 하이픈. `domain` 허용값은 `<VAULT>/AGENTS.md`를 따른다.

```yaml
---
type: session
domain: work                   # 볼트 스키마의 도메인 중 하나
project: my-service            # 작업한 저장소·디렉터리 이름. 볼트 자체면 볼트 이름
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [git, ssh]
sources: []                    # 참조한 위키 페이지가 있으면
status: stable
---
```

본문 네 부분. **셋째를 생략하지 않는다.**

```markdown
## 무엇을·왜
## 결과
## 알아낸 것        ← 이게 없으면 기록할 이유가 없다
## 후속 과제
```

"알아낸 것"에는 **재현 조건과 판별법**을 쓴다. "SSH가 안 됐다"가 아니라
"`git push` 출력에 `To https://`가 찍히면 전역 insteadOf가 SSH를 가로챈 것"처럼.

### 2. index.md 갱신

`<VAULT>/wiki/index.md`의 `## Sessions` 절에 추가:

```markdown
- [[YYYY-MM-DD-GitHub-SSH-연동]] — insteadOf 규칙이 SSH를 HTTPS로 돌리는 함정
```

### 3. log.md 갱신

`<VAULT>/wiki/log.md` 맨 아래에 추가:

```markdown
## [YYYY-MM-DD] session | <작업 제목>

<2~3줄 요약>
```

### 4. 관련 페이지 연결

기록에 등장한 개체·개념 페이지가 볼트에 이미 있으면 `[[링크]]`를 건다.
없는데 반복될 것 같으면 **만들지 말고 제안만 한다** — 세션 기록이 개체 페이지를
양산하면 위키가 지저분해진다.

### 5. 커밋 (볼트가 git 저장소일 때)

```bash
cd "<VAULT>" && git add wiki/ && git commit -m "session: <작업 제목>"
```

원격이 설정돼 있으면 `git push`까지. 볼트가 git 저장소가 아니면 이 단계를 건너뛴다.
푸시가 실패하면(오프라인 등) 보고만 하고 넘어간다. 로컬 커밋은 남는다.

## 흔한 실패

| 실패 | 결과 |
|---|---|
| "알아낸 것"을 비움 | 나중에 읽어도 쓸모없는 일지가 됨 |
| 무슨 일이 있었는지만 나열 | 재현 조건이 없어 다음에 못 씀 |
| 택하지 않은 대안을 안 씀 | 같은 대안을 또 검토하게 됨 |
| `index.md` 누락 | 질의 때 못 찾음 = 없는 것과 같음 |
| 사소한 세션까지 기록 | 신호 대 잡음비 하락 |
| 상대경로 사용 | 볼트 밖에서 호출되므로 엉뚱한 곳에 씀 |
