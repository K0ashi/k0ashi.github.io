-- Supabase → SQL Editor → вставить всё → Run
create table status(id int primary key default 1 check(id=1), act text default 'scroll', busy bool default false,
  until_at timestamptz, outside bool default false, dest text, eta_min int, wake_at timestamptz, updated_at timestamptz default now());
insert into status(id) values(1);
create table activities(id text primary key, name text not null, icon text, color text, sort int default 0);
insert into activities values
('work','Работа','💼','#a9c8f0',1),('sleep','Сон','😴','#cdbdf0',2),('walk','Гуляю','🚶','#b4e0cc',3),
('play','Играю','🎮','#f2b8c6',4),('stream','Смотрю стрим','📺','#f5cfa8',5),('yt','Смотрю ютуб','▶️','#f2b8c6',6),
('movie','Смотрю фильм/сериал','🎬','#cdbdf0',7),('scroll','Думскроллю','📱','#f1e3a1',8),('dog','Гуляю с собакой','🐕','#f5cfa8',9);
create table schedule(id uuid primary key default gen_random_uuid(), day date not null, at text, title text not null, kind text default 's');
create table kicks(id uuid primary key default gen_random_uuid(), name text not null check(length(name) between 1 and 40), created_at timestamptz default now());
create table subs(id uuid primary key default gen_random_uuid(), endpoint text unique not null, data jsonb not null,
  role text not null check(role in ('owner','friend')), name text);

alter table status enable row level security; alter table activities enable row level security;
alter table schedule enable row level security; alter table kicks enable row level security; alter table subs enable row level security;

-- все читают статус, занятия, расписание; менять может только вошедший (ты)
create policy r on status for select to anon,authenticated using(true);
create policy w on status for update to authenticated using(true);
create policy r on activities for select to anon,authenticated using(true);
create policy w on activities for all to authenticated using(true) with check(true);
create policy r on schedule for select to anon,authenticated using(true);
create policy w on schedule for all to authenticated using(true) with check(true);
-- пинать могут все, читать пинки только ты
create policy i on kicks for insert to anon,authenticated with check(true);
create policy r on kicks for select to authenticated using(true);
-- друзья подписываются на уведомления, ты — как owner
create policy i1 on subs for insert to anon with check(role='friend');
create policy i2 on subs for insert to authenticated with check(true);

create function unsub(e text) returns void language sql security definer set search_path=public as
$$ delete from subs where endpoint=e and (role='friend' or auth.uid() is not null) $$;
grant execute on function unsub(text) to anon,authenticated;

alter publication supabase_realtime add table status, kicks, activities, schedule;
