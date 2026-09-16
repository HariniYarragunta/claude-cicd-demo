#!/usr/bin/env bash
# Calls the Groq chat completions API with a system/user prompt pair and
# prints the model's reply text to stdout. Shared by the CI workflows so the
# request-building and error-handling logic lives in one place.
#
# Usage: groq-chat.sh --system-file <path> --user-file <path> [--json] [--model <id>]
#   --json  requests JSON-object output (response_format: json_object)
#
# Requires GROQ_API_KEY in the environment.
set -euo pipefail

MODEL="llama-3.3-70b-versatile"
JSON_MODE=0
SYSTEM_FILE=""
USER_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --system-file) SYSTEM_FILE="$2"; shift 2 ;;
    --user-file) USER_FILE="$2"; shift 2 ;;
    --json) JSON_MODE=1; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "groq-chat.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ -z "${GROQ_API_KEY:-}" ]; then
  echo "groq-chat.sh: GROQ_API_KEY is not set" >&2
  exit 1
fi
if [ -z "$SYSTEM_FILE" ] || [ -z "$USER_FILE" ]; then
  echo "groq-chat.sh: --system-file and --user-file are required" >&2
  exit 1
fi

RESPONSE_FORMAT='null'
if [ "$JSON_MODE" -eq 1 ]; then
  RESPONSE_FORMAT='{"type":"json_object"}'
fi

PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --rawfile system "$SYSTEM_FILE" \
  --rawfile user "$USER_FILE" \
  --argjson response_format "$RESPONSE_FORMAT" \
  '{model: $model, temperature: 0,
    messages: [{role: "system", content: $system}, {role: "user", content: $user}]}
   + (if $response_format == null then {} else {response_format: $response_format} end)')

RESPONSE=$(curl -sS https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
if [ -n "$ERROR" ]; then
  echo "groq-chat.sh: Groq API error: $ERROR" >&2
  exit 1
fi

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')
if [ -z "$CONTENT" ]; then
  echo "groq-chat.sh: no content in Groq response: $RESPONSE" >&2
  exit 1
fi

echo "$CONTENT"
