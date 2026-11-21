-- 회원가입한 사용자 정보를 관리하는 프로필 테이블
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  username text unique,
  full_name text,
  avatar_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_length check (username is null or char_length(username) between 3 and 30)
);

comment on table public.profiles is '사용자 프로필 정보 (auth.users와 1:1)';

-- RLS 활성화
alter table public.profiles enable row level security;

-- 인증된 사용자는 모든 프로필 조회 가능
create policy "인증된 사용자는 프로필 조회 가능"
  on public.profiles for select
  to authenticated
  using (true);

-- 본인 프로필만 생성 가능
create policy "본인 프로필만 생성 가능"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

-- 본인 프로필만 수정 가능
create policy "본인 프로필만 수정 가능"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- updated_at 자동 갱신 함수
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- 회원가입 시 프로필 자동 생성 함수
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

-- 트리거 함수는 API로 직접 호출되지 않도록 실행 권한 회수
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 기존 가입자 프로필 백필
insert into public.profiles (id, email, full_name, avatar_url)
select id, email, raw_user_meta_data ->> 'full_name', raw_user_meta_data ->> 'avatar_url'
from auth.users
on conflict (id) do nothing;
