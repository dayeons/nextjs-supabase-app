import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import prettier from "eslint-config-prettier/flat";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    rules: {
      // 사용하지 않는 변수: 언더스코어(_)로 시작하면 허용
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
      // 타입 전용 import는 `import type`으로 분리
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports", fixStyle: "inline-type-imports" },
      ],
      // 디버깅용 console.log 방지 (warn/error는 허용)
      "no-console": ["warn", { allow: ["warn", "error"] }],
      eqeqeq: ["error", "always", { null: "ignore" }],
      "prefer-const": "error",
    },
  },
  // Prettier와 충돌하는 포맷 관련 규칙 비활성화 (반드시 마지막)
  prettier,
  globalIgnores([
    // eslint-config-next 기본 제외 대상
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // Supabase MCP로 생성되는 파일 (수동 편집 금지)
    "lib/supabase/database.types.ts",
  ]),
]);

export default eslintConfig;
