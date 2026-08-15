import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

type PushRow = {
  endpoint: string;
  p256dh: string;
  auth: string;
};

type TaskRow = {
  title: string;
  due_date: string | null;
  priority: number;
};

const JERUSALEM_DATE = new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Jerusalem",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});

function todayInJerusalem(): string {
  return JERUSALEM_DATE.format(new Date());
}

function taskDate(value: string | null): string | null {
  if (!value) return null;
  return JERUSALEM_DATE.format(new Date(value));
}

function buildPayload(tasks: TaskRow[]): { title: string; body: string; url: string } | null {
  const today = todayInJerusalem();
  const overdue = tasks
    .filter((task) => {
      const date = taskDate(task.due_date);
      return date != null && date < today;
    })
    .sort((a, b) => a.priority - b.priority);
  const dueToday = tasks
    .filter((task) => taskDate(task.due_date) === today)
    .sort((a, b) => a.priority - b.priority);

  if (overdue.length === 0 && dueToday.length === 0) {
    return null;
  }

  const parts: string[] = [];
  if (overdue.length > 0) parts.push(`${overdue.length} באיחור`);
  if (dueToday.length > 0) parts.push(`${dueToday.length} להיום`);

  const preview = [...overdue, ...dueToday]
    .map((task) => task.title)
    .filter((title) => title.trim().length > 0)
    .slice(0, 3)
    .join(" · ");

  return {
    title: "ניהול החיים",
    body: preview.length > 0 ? `${parts.join(" · ")}: ${preview}` : parts.join(" · "),
    url: "/",
  };
}

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const admin = createClient(supabaseUrl, serviceKey);

    const { data: secrets, error: secretsError } = await admin.rpc(
      "life_app_internal_secrets",
    );
    if (secretsError) {
      throw secretsError;
    }

    const secretMap = (secrets ?? {}) as Record<string, string>;
    const cronSecret = secretMap["cron_secret"];
    const vapidPublic = secretMap["vapid_public"];
    const vapidPrivate = secretMap["vapid_private"];
    const provided = req.headers.get("x-cron-secret") ?? "";

    if (!cronSecret || provided !== cronSecret) {
      return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
    }
    if (!vapidPublic || !vapidPrivate) {
      throw new Error("Missing VAPID keys");
    }

    const [{ data: tasks, error: tasksError }, { data: subs, error: subsError }] =
      await Promise.all([
        admin
          .from("tasks")
          .select("title, due_date, priority")
          .eq("is_completed", false),
        admin.from("push_subscriptions").select("endpoint, p256dh, auth"),
      ]);
    if (tasksError) throw tasksError;
    if (subsError) throw subsError;

    const payload = buildPayload((tasks ?? []) as TaskRow[]);
    const subscriptions = (subs ?? []) as PushRow[];
    if (!payload) {
      return Response.json({ ok: true, sent: 0, reason: "no_due_tasks" });
    }
    if (subscriptions.length === 0) {
      return Response.json({ ok: true, sent: 0, reason: "no_subscriptions" });
    }

    webpush.setVapidDetails("mailto:life-app@local", vapidPublic, vapidPrivate);
    const body = JSON.stringify(payload);
    let sent = 0;
    const stale: string[] = [];

    for (const row of subscriptions) {
      try {
        await webpush.sendNotification(
          {
            endpoint: row.endpoint,
            keys: { p256dh: row.p256dh, auth: row.auth },
          },
          body,
        );
        sent += 1;
      } catch (error) {
        const status = (error as { statusCode?: number }).statusCode;
        if (status === 404 || status === 410) {
          stale.push(row.endpoint);
        } else {
          console.error("web-push failed", error);
        }
      }
    }

    if (stale.length > 0) {
      await admin.from("push_subscriptions").delete().in("endpoint", stale);
    }

    return Response.json({ ok: true, sent, stale: stale.length });
  } catch (error) {
    console.error(error);
    return Response.json(
      { error: error instanceof Error ? error.message : "unknown" },
      { status: 500 },
    );
  }
});
