#!/usr/bin/env bash
# SessionStart: 위키 규칙("먼저 참조·먼저 기록 제안")과 볼트 경로를 세션 컨텍스트에 주입한다.
# 볼트 경로 = $LLM_WIKI_VAULT, 없으면 <config>/llm-wiki/vault-path 첫 줄. wiki-init 이 파일을 쓴다.

set -u

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PATH_FILE="$CONFIG_DIR/llm-wiki/vault-path"

vault="${LLM_WIKI_VAULT:-}"
if [ -z "$vault" ] && [ -f "$PATH_FILE" ]; then
  IFS= read -r vault < "$PATH_FILE" || true
fi
vault="${vault%$'\r'}"

if [ -n "$vault" ]; then
  # 줄 단위 치환 — ${s//pat/rep} 는 bash 5.2 에서 & 를 특수문자로 해석하므로 쓰지 않는다
  context=""
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      *'{{VAULT_PATH}}'*) line="${line%%\{\{VAULT_PATH\}\}*}${vault}${line#*\{\{VAULT_PATH\}\}}" ;;
    esac
    context+="$line"$'\n'
  done < "$HOOK_DIR/wiki-rules.md"
else
  context="llm-wiki 플러그인이 설치돼 있지만 볼트가 아직 설정되지 않았다. 사용자가 위키를 언급하면 wiki-init 스킬로 볼트를 만들거나 경로를 등록하도록 안내한다. 그 외에는 이 사실을 언급하지 않는다."
fi

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(escape_for_json "$context")"
