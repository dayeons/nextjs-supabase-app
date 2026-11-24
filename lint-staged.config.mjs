/**
 * 스테이징된 파일에만 린트/포맷을 적용합니다.
 * - --no-warn-ignored: eslint 제외 대상(database.types.ts 등)이 스테이징돼도
 *   "File ignored" 경고로 --max-warnings=0에 걸리지 않도록 합니다.
 * - 타입체크는 파일 단위로 실행할 수 없어 .husky/pre-commit에서 별도로 실행합니다.
 */
const config = {
  "*.{ts,tsx,mjs}": [
    "eslint --fix --max-warnings=0 --no-warn-ignored",
    "prettier --write",
  ],
  "*.{json,css}": "prettier --write",
};

export default config;
