---
name: wiki-init
description: Use when the user wants to create a new LLM wiki vault, set up the llm-wiki plugin for the first time, or connect an existing vault — "위키 만들어줘", "LLM 위키 시작", "볼트 초기화", "위키 경로 설정". Also use when another wiki skill cannot find the vault path.
---

# 위키 초기화 (Init)

## 핵심 원칙

**볼트 뼈대를 깔고, 볼트 경로를 파일 한 곳에 등록한다.**
경로 파일: `~/.claude/llm-wiki/vault-path` (`CLAUDE_CONFIG_DIR`을 쓰면 그 아래). 절대경로 한 줄.

플러그인의 SessionStart 훅이 매 세션 이 파일을 읽어 볼트 경로와 "먼저 참조·먼저 기록 제안"
규칙(`hooks/wiki-rules.md`)을 컨텍스트에 넣는다. **전역 CLAUDE.md는 건드리지 않는다.**

템플릿은 이 스킬 디렉터리 안의 `template/`다(스킬 로드 시 표시되는 base directory 기준).
규칙 원문은 플러그인 루트의 `hooks/wiki-rules.md` — base directory에서 `../../hooks/wiki-rules.md`.

## 절차

### 1. 세 가지를 묻는다 (한 번에)

- **볼트 위치** — 절대경로. 예: `C:\Users\<me>\Documents\my-wiki`, `~/my-wiki`
- **볼트 이름** — 기본값은 폴더명
- **도메인** — 프론트매터 `domain`에 쓸 값. 기본값 `work, personal, research`.
  사람마다 다르다(예: `rnd` 추가). 나중에 `AGENTS.md`에서 바꿀 수 있다.

기존 볼트를 연결만 하려는 경우(이미 `wiki/index.md`가 있음)는 2~3을 건너뛰고 4로 간다.

### 2. 대상 확인 — 덮어쓰지 않는다

대상 폴더가 존재하고 비어 있지 않으면 **멈추고 보여준다.** 기존 Obsidian 볼트에
위키를 얹는 경우라면 충돌하는 파일(`AGENTS.md`, `CLAUDE.md`, `wiki/`)만 확인받는다.
아무것도 덮어쓰지 않는다.

### 3. 템플릿 복사

`template/` 전체를 대상에 복사하고:

- `gitignore` → `.gitignore`로 이름을 바꾼다 (플러그인 안에서 git 규칙이 작동하지 않도록 점 없이 보관돼 있다)
- `{{VAULT_NAME}}`, `{{TODAY}}`(YYYY-MM-DD), `{{DOMAINS}}`(`work | personal | research` 형태),
  `{{DOMAIN_DIRS}}`(`{work,personal,research}` 형태)를 치환한다
- `raw/` 와 도메인별 하위 폴더, `raw/assets/`를 만든다

git을 쓸지 묻고, 쓰면 `git init` 후 첫 커밋까지만 한다. **원격 연결·푸시는 사용자가 한다.**

### 4. 경로 등록

`~/.claude/llm-wiki/vault-path`에 볼트 절대경로 한 줄을 쓴다(폴더가 없으면 만든다).
이미 파일이 있으면 기존 경로를 보여주고 바꿀지 묻는다.

- 이 파일이 규칙 주입의 스위치다. 없으면 훅은 "볼트 미설정" 안내만 넣고, 먼저 참조·먼저 제안이 동작하지 않는다
- 전역 CLAUDE.md에 이미 `## LLM 위키` 절이나 비슷한 위키 규칙이 있으면 **훅과 중복**된다고 알리고, 지울지 사용자에게 맡긴다
- Codex 사용자면 플러그인 훅이 Codex에서 돌지 않을 수 있다 — `hooks/wiki-rules.md`의 `{{VAULT_PATH}}`를
  치환한 내용을 `~/.codex/AGENTS.md`에 넣을지 **승인받고** 추가한다

### 5. 안내

- Obsidian에서 볼트 폴더를 연다 ("폴더를 보관소로 열기")
- 권장 플러그인: `obsidian-git`, `dataview`
- 첫 사용: 자료를 `raw/<도메인>/`에 넣고 "이거 위키에 넣어줘" → `wiki-ingest`
- **새 세션부터** 훅이 규칙을 주입한다 (지금 세션은 `/clear` 해도 된다)

## 흔한 실패

| 실패 | 결과 |
|---|---|
| 기존 폴더에 그냥 복사 | 사용자 노트 덮어씀 |
| 경로 파일 등록 생략 | 다른 스킬이 볼트를 못 찾고, 먼저 제안·참조도 안 함 |
| 전역 CLAUDE.md에 규칙을 또 추가 | 훅과 이중 주입 |
| `gitignore` 이름 안 바꿈 | `raw/`가 git에 올라가 원본 문서 유출 |
| 상대경로로 등록 | 다른 프로젝트에서 엉뚱한 곳을 봄 |
