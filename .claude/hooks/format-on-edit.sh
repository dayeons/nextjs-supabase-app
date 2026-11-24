#!/bin/sh
# PostToolUse 훅: Claude가 Write/Edit한 파일을 Prettier + ESLint로 즉시 정리합니다.
# - 포맷/자동 수정 결과는 조용히 반영합니다.
# - 자동 수정이 불가능한 ESLint 에러만 stderr로 출력하고 exit 2로 Claude에게 알립니다.
# - jq 설치 여부와 무관하게 동작하도록 JSON 파싱은 node로 합니다.

input=$(cat)

file=$(printf '%s' "$input" | node -e '
let s = "";
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  try {
    const j = JSON.parse(s);
    process.stdout.write((j.tool_input && j.tool_input.file_path) || "");
  } catch {}
});
')

# 파일 경로가 없거나 존재하지 않으면 무시
[ -n "$file" ] && [ -f "$file" ] || exit 0

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# 프로젝트 밖 파일은 건드리지 않음
case "$file" in
  "$project_dir"/*) ;;
  *) exit 0 ;;
esac

case "$file" in
  *.ts | *.tsx | *.mjs | *.json | *.css) ;;
  *) exit 0 ;;
esac

cd "$project_dir" || exit 0

# .prettierignore 대상은 prettier가 알아서 건너뜁니다.
npx --no-install prettier --write --ignore-unknown "$file" >/dev/null 2>&1

case "$file" in
  *.ts | *.tsx | *.mjs)
    if ! out=$(npx --no-install eslint --fix --no-warn-ignored "$file" 2>&1); then
      printf '%s\n' "$out" >&2
      exit 2
    fi
    ;;
esac

exit 0
