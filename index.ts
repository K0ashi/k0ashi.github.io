import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";
webpush.setVapidDetails(Deno.env.get("VAPID_SUBJECT")!, Deno.env.get("VAPID_PUBLIC")!, Deno.env.get("VAPID_PRIVATE")!);
const sb = createClient(Deno.env.get("SUPABASE_URL")!, (() => { try { return JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!)["default"]; } catch { return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!; } })());
Deno.serve(async (req) => {
  if (req.headers.get("x-secret") !== Deno.env.get("HOOK_SECRET")) return new Response("no", { status: 401 });
  const p = await req.json();
  let role = "", msg: Record<string, unknown> = {};
  if (p.table === "kicks" && p.type === "INSERT") {
    const { data: st } = await sb.from("status").select("act").eq("id", 1).single();
    role = "owner";
    msg = { title: `${p.record.name} пнул тебя`, tag: "kick", sleep: st?.act === "sleep" };
  } else if (p.table === "status" && p.type === "UPDATE" && p.old_record?.outside && !p.record.outside) {
    role = "friend"; msg = { title: "Сеня вернулся домой", tag: "home" };
  } else return new Response("skip");
  const { data } = await sb.from("subs").select("*").eq("role", role);
  await Promise.all((data ?? []).map(async (s) => {
    try { await webpush.sendNotification(s.data, JSON.stringify(msg)); }
    catch (e) { if (e.statusCode === 404 || e.statusCode === 410) await sb.from("subs").delete().eq("id", s.id); }
  }));
  return new Response("ok");
});
