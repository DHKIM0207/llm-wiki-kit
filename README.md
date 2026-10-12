# llm-wiki — LLM이 관리하는 지식 위키

AI 코딩 에이전트(Claude Code, Codex)가 Obsidian 볼트를 **직접 쓰고 관리하는** 개인 지식 위키용 플러그인.
공개된 "LLM Wiki" 패턴 아이디어 문서를 실제 업무에 몇 달 써보며 다듬은 절차다.

## 왜 RAG가 아니라 위키인가

파일을 올려두고 질문할 때마다 검색하는 방식(RAG)은 매번 지식을 처음부터 다시 짜맞춘다. 쌓이는 게 없다.
이 방식은 **자료를 넣을 때** LLM이 읽고 기존 페이지들에 통합해 둔다. 개체·개념 페이지가 자료를 거듭할수록
두꺼워지고, 모순은 표시되고, 좋은 답변은 다시 위키로 돌아간다. 사람은 자료를 모으고 질문만 한다.

| 역할 | 누가 |
|---|---|
| 자료 수집, 방향 잡기, 질문 | 사람 |
| 요약·상호참조·분류·모순 표시·기록 관리 | LLM |
| 읽기·탐색 (그래프 뷰, 백링크) | Obsidian |

## 들어 있는 것

| 스킬 | 언제 |
|---|---|
| `wiki-init` | 새 볼트 만들기 / 기존 볼트 경로 등록 |
| `wiki-ingest` | `raw/`에 넣은 자료를 위키에 통합 ("이거 위키에 넣어줘") |
| `wiki-query` | 위키에 질문 — 볼트 안·밖 어디서든. 작업 시작 전 능동 참조도 이것 |
| `wiki-lint` | 모순·고아 페이지·깨진 링크·낡은 아이디어 점검 |
| `wiki-log` | 다른 프로젝트에서 한 작업(삽질·설계 결정·환경 함정)을 위키에 기록 |

| 훅 | 하는 일 |
|---|---|
| SessionStart | 매 세션 볼트 경로 + **"작업 전 위키 먼저 참조 · 작업 후 기록 먼저 제안"** 규칙을 컨텍스트에 주입 (`hooks/wiki-rules.md`) |
| PreCompact | 컨텍스트 압축 직전에 "위키에 남길 작업이 있으면 기록을 제안하라"고 상기 — 긴 세션에서 제안을 놓치지 않게 |

그래서 전역 CLAUDE.md를 따로 고치지 않아도, 설치 + `wiki-init`만 하면 Claude가 알아서 묻고 찾아본다.

플러그인으로 설치하면 이름에 접두사가 붙는다 — `/llm-wiki:wiki-query` 식. 평소엔 "위키에 넣어줘"처럼
말로 요청하면 알아서 고른다.

`skills/wiki-init/template/`에 새 볼트 뼈대(스키마 `AGENTS.md`, `index.md`, `log.md`, 폴더, `.gitignore`)가 있다.

## 설치 (Claude Code)

> 한 장짜리 설치 안내: [docs/설치안내.pdf](docs/설치안내.pdf) (원본 `docs/설치안내.html` — 고친 뒤 Edge/Chrome에서 PDF로 인쇄)

Claude Code 대화창에서:

```
/plugin marketplace add DHKIM0207/llm-wiki-kit
/plugin install llm-wiki@llm-wiki-kit
```

그 다음 새 세션에서:

```
LLM 위키 만들어줘
```

→ `wiki-init`이 볼트 위치·이름·도메인을 묻고, 뼈대를 깔고, 경로를 `~/.claude/llm-wiki/vault-path`에
등록한다. **다음 세션부터**(또는 `/clear` 후) 훅이 규칙을 넣기 시작한다.

### 플러그인 없이 수동 설치

`skills/` 아래 다섯 폴더를 `~/.claude/skills/`에 복사하고, 훅 대신 `hooks/wiki-rules.md`의
내용을 `{{VAULT_PATH}}`만 바꿔 `~/.claude/CLAUDE.md` 끝에 붙인다. (PreCompact 상기는 빠진다.)

### Codex

Codex CLI(0.162 기준)는 Claude Code 마켓플레이스 형식을 그대로 읽는다. 터미널에서:

```bash
codex plugin marketplace add DHKIM0207/llm-wiki-kit
codex plugin add llm-wiki@llm-wiki-kit
codex plugin list        # llm-wiki@llm-wiki-kit  installed, enabled 확인
```

새 Codex 세션에서 `LLM 위키 만들어줘` → `wiki-init`. 스킬은 `llm-wiki:wiki-query` 식 이름으로 잡힌다.

플러그인 훅(먼저 참조·먼저 제안 규칙 주입)이 Codex에서 도는지는 아직 검증하지 않았다.
그래서 `wiki-init`이 Codex 사용자에게 `hooks/wiki-rules.md`(볼트 경로 치환)를 `~/.codex/AGENTS.md`에
붙일지 묻는다 — 붙이면 훅 없이도 규칙이 적용된다.
볼트 스키마가 `AGENTS.md`이고 `CLAUDE.md`는 이를 `@AGENTS.md`로 import만 하므로 두 에이전트가 같은 규칙을 읽는다.

업데이트: `codex plugin marketplace upgrade llm-wiki-kit` 후 `codex plugin add llm-wiki@llm-wiki-kit`.

## 설정은 파일 한 줄

`~/.claude/llm-wiki/vault-path` 에 볼트 절대경로 한 줄. `wiki-init`이 쓴다.
환경변수 `LLM_WIKI_VAULT`가 있으면 그게 우선한다. 볼트를 옮기면 이 파일만 고치면 된다.

파일이 없으면 훅은 규칙을 넣지 않고 "볼트 미설정" 안내만 한다 — 설치만 해두고 안 쓰는 사람에게는 조용하다.

## 볼트 구조

```
raw/            원본 자료 — 사람 소유, LLM은 읽기만. git 제외
wiki/sources/   자료 하나당 요약
wiki/entities/  사람·조직·장비·시스템·제품
wiki/concepts/  기술·개념·방법론
wiki/syntheses/ 여러 자료를 종합한 결론
wiki/sessions/  코딩 에이전트 작업 기록
wiki/ideas/     앞으로 개발·개선할 것
wiki/index.md   카탈로그 — 질의 때 가장 먼저 읽는다
wiki/log.md     시간순 기록 (append-only)
AGENTS.md       스키마: 페이지 형식·불변 규칙 (함께 고쳐 나간다)
```

폴더를 도메인(업무/개인/연구)이 아니라 **유형**으로 나누고 도메인은 프론트매터로만 표시한다.
그래야 업무에서 만난 장비가 연구 과제의 근거로 이어지는 식의 연결이 생긴다.

## 설계상 핵심 규칙

- **자료 하나가 10~15개 페이지를 건드린다.** 요약 하나 던져두는 건 위키가 아니라 요약 폴더다.
- **수집 전에 요점 3~5개를 사람과 먼저 맞춘다.** 방향이 어긋나면 이후 페이지가 전부 어긋난다.
- **모순은 덮어쓰지 않는다.** 양쪽에 `status: contested`를 달고 사람이 판정한다.
- **근거 없는 문장을 쓰지 않는다.** 모든 페이지에 `sources`.
- **좋은 답변은 `syntheses/`로 되돌린다.** 채팅에만 남기면 사라진다.
- **점검은 보고서다.** 기계적으로 명백한 것만 고치고 판단은 사람에게 묻는다. 삭제하지 않는다.

## 권장 환경

- Obsidian + `obsidian-git`(자동 커밋·동기화) + `dataview`(프론트매터 질의)
- 셸 예제는 bash 기준 — Windows는 Git Bash
- 검색 엔진은 필요 없다. 페이지 수백 개까지는 `index.md`로 충분하다.

## 하지 않는 것

- 임베딩 기반 RAG 인프라
- 모든 세션 자동 기록(Stop 훅) — 사소한 세션까지 쌓여 위키가 지저분해진다. 훅은 **상기만** 하고, 기록은 LLM이 제안해 사람이 승인한다.

## 알려진 한계

- 먼저 참조·먼저 제안은 규칙을 **따르는 경향**이지 보장이 아니다. 가끔 빠뜨린다.
- 훅 스크립트는 bash로 돈다 — Windows는 Git Bash가 필요하다(Claude Code 설치 요건과 같다).
- 이미 전역 CLAUDE.md에 비슷한 위키 규칙을 둔 사람은 훅과 중복되니 한쪽을 지운다.
