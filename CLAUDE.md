# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 명령어

```bash
npm run dev           # 개발 서버
npm run build         # 프로덕션 빌드
npm run lint          # ESLint (eslint .)
npm run lint:fix      # ESLint 자동 수정
npm run typecheck     # tsc --noEmit
npm run format        # Prettier 적용
npm run format:check  # Prettier 검사만
npm run check-all     # typecheck + lint + format:check (작업 완료 전 실행)
```

테스트 러너는 설정되어 있지 않습니다.

### 코드 품질 도구
- **ESLint**: `eslint.config.mjs` (flat config, `eslint-config-next` 16 + `eslint-config-prettier`). `.next/**`, `lib/supabase/database.types.ts`는 제외 대상입니다.
- **Prettier**: `.prettierrc`. 가이드 문서가 아니라 **현재 코드 스타일 기준**(세미콜론, 큰따옴표, 후행 쉼표 all, 2칸, 80자)이며 `prettier-plugin-tailwindcss`가 `cn`/`cva` 안의 클래스도 정렬합니다. 마크다운, `docs/`, `.claude/`, `supabase/migrations/`, `.mcp.json`, `database.types.ts`는 `.prettierignore`로 제외됩니다.
- **pre-commit** (Husky): `lint-staged`(스테이징된 파일에 `eslint --fix` + `prettier --write`) 후 `npm run typecheck`를 실행하며, 실패하면 커밋이 차단됩니다. 훅을 우회(`--no-verify`)하지 마세요.
- **Claude Code 훅** (`.claude/settings.json`): Write/Edit 직후 `.claude/hooks/format-on-edit.sh`가 해당 파일에 Prettier와 `eslint --fix`를 적용합니다. 자동 수정이 불가능한 ESLint 에러는 Claude에게 전달되니 바로 고치세요.
- **CI** (`.github/workflows/ci.yml`): push/PR 시 `npm run check-all`을 실행합니다.
- `react-hooks/set-state-in-effect`처럼 의도된 패턴에만 `eslint-disable-next-line`을 사유 주석과 함께 사용하세요(예: `components/theme-switcher.tsx`).

환경변수(`.env.local`): `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (anon key가 아닌 publishable key 사용).

## 아키텍처

Supabase 공식 Next.js 스타터(Create Next App 기반) 위에 구축된 App Router 프로젝트입니다. `src/` 디렉터리 없이 루트에 `app/`, `components/`, `lib/`가 있으며, 경로 별칭은 `@/*`입니다. (`docs/guides/project-structure.md`는 `src/` 구조를 설명하지만 실제 구조와 다릅니다.)

### 인증 / Supabase 클라이언트
- **`proxy.ts`** (루트): Next.js 16 스타일의 `middleware` 대체 파일. `lib/supabase/proxy.ts`의 `updateSession`을 호출해 모든 요청에서 쿠키 기반 세션을 갱신하고, 비로그인 사용자를 `/auth/login`으로 리다이렉트합니다. `/`, `/login*`, `/auth*`만 공개 경로입니다.
- `updateSession` 안에서 `createServerClient`와 `supabase.auth.getClaims()` 사이에 다른 코드를 넣지 마세요(임의 로그아웃 발생). 반환한 `supabaseResponse`는 그대로 반환해야 쿠키가 유지됩니다.
- 클라이언트 사용처별로 `lib/supabase/client.ts`(브라우저), `lib/supabase/server.ts`(서버 컴포넌트/액션)를 구분하며, 서버 클라이언트는 전역 변수에 저장하지 않고 요청마다 새로 생성합니다.
- `hasEnvVars`(`lib/utils.ts`)는 환경변수 미설정 시 프록시 검사를 건너뛰고 경고 UI를 띄우는 튜토리얼용 체크입니다.

### 라우트
- `app/auth/*`: login, sign-up, sign-up-success, forgot-password, update-password, confirm(이메일 OTP 확인 라우트), error
- `app/protected/*`: 로그인 필요 영역 (자체 레이아웃 보유)
- `components/tutorial/`, `deploy-button.tsx`, `env-var-warning.tsx`, `hero.tsx` 등은 스타터 데모용 코드입니다.

### 데이터베이스
- 마이그레이션은 `supabase/migrations/`에 SQL로 관리 (현재 `profiles` 테이블: `auth.users`와 1:1, RLS 활성화, `updated_at` 트리거). 마이그레이션 주석/정책명은 한국어입니다.
- `lib/supabase/database.types.ts`는 생성된 타입 파일입니다. 스키마 변경 후 Supabase MCP(`generate_typescript_types`)로 재생성하세요. 수동 편집 금지.
- `.mcp.json`의 Supabase MCP는 `read_only=true`로 연결되어 있어 MCP로 스키마를 변경할 수 없습니다. 변경은 마이그레이션 파일로 작성하세요.

### UI
- shadcn/ui (`new-york` 스타일, neutral, CSS 변수, lucide 아이콘), Tailwind CSS 3 (`tailwind.config.ts`), `next-themes`로 다크모드. 컴포넌트는 `components/ui/`에 추가 (`@/components`, `@/lib/utils` 별칭).

## 프로젝트 도구
- `.mcp.json`: supabase, playwright, context7, sequential-thinking, shadcn, shrimp-task-manager MCP 설정.
- `.claude/`에 커스텀 에이전트, `docs`/`git` 슬래시 커맨드, 자동 포맷 훅(`settings.json`에 등록됨)이 있습니다. `hooks/notification-hook.sh`, `hooks/stop-hook.sh`(Slack 알림)는 스크립트만 있고 어떤 settings에도 연결되어 있지 않으며, `.env`의 `SLACK_WEBHOOK_URL`이 필요합니다.
- `docs/guides/`에 컴포넌트 패턴, react-hook-form, Next.js 15, 스타일링 가이드가 있습니다 (참고 시 실제 코드 구조와 대조할 것).

## 언어 규칙
응답·코드 주석·커밋 메시지·문서는 한국어, 변수명/함수명은 영어로 작성합니다.
