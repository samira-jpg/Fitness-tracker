# Fitness Tracker

A workout logger for the Full Body A/B plan (v6), built to be used one-handed in the gym.
Static page, no build step: open `index.html` and that's the whole app.

## What it does

- **Train** — the home screen names today's workout (A or B, alternating from the last one you
  logged), resumes a session you left half-finished, and lists recent sessions.
- **Session runner** — one exercise at a time. Weight, RPE and reps per set, with last session's
  numbers inline and as a ghost in each empty field. `✓` accepts the ghost weight, starts the rest
  countdown from the plan's own rest time, and puts the cursor in the RPE box.
  Every change saves immediately, so closing the tab mid-workout loses nothing.
- **Progress** — KPIs, sessions per week, progress by exercise, a comparison chart, the calendar
  and the full set-by-set log. Two ways to share it with a coach (below).
- **Plan** — the programme itself: both workouts, the warm-up, muscle groups and past plan versions.

Reps default to what the plan prescribes and are editable per set, so volume and estimated 1RM
reflect what was actually done.

## Setup

### 1. Database

Already applied to the Supabase project in `config.js`. To recreate it elsewhere, run
[`supabase/schema.sql`](supabase/schema.sql) in the SQL editor.

Two tables: `sessions` (one row per workout, `items` is the JSON of exercises and their sets) and
`share_links` (tokens that let a coach read). Row-level security means a signed-in user only ever
sees their own rows.

### 2. Your login

Supabase Dashboard → **Authentication → Users → Add user → Create new user**.
Set an email and password and tick **Auto Confirm User**, so no confirmation email is needed.
That's the account you sign into the app with.

### 3. Hosting

GitHub Pages: **Settings → Pages → Source: Deploy from a branch → `main` / root**.
The site then lives at `https://<user>.github.io/fitness-tracker/`.

Any static host works — there's no server side.

## Sharing with a coach

Two options, both from the Progress tab:

- **Live link** — "Create a live link" makes a token and gives you a URL ending in `#coach=<token>`.
  Anyone with it sees Progress, read-only, with no account and no sign-in. It always shows your
  latest sessions. Revoke it from the same place and it stops working immediately.
- **Snapshot** — "Save snapshot for coach" builds a single HTML file with every number baked in.
  No account, no internet, prints cleanly. It's a point-in-time copy and doesn't update.

The live link reads through `sessions_for_token()`, which returns nothing without a valid,
unrevoked token and can never write.

## `config.js`

```js
window.FITNESS_CONFIG = { url: "https://<project>.supabase.co", anonKey: "sb_publishable_..." };
```

Both values are public by design — they identify the project, they don't grant access.
Row-level security is what protects the data. Don't put a service-role key here.

## Files

| Path | What it is |
|---|---|
| `index.html` | the whole app — markup, styles, logic |
| `config.js` | Supabase project URL and publishable key |
| `vendor/supabase.js` | supabase-js 2.119.2, vendored so the page has no CDN dependency |
| `supabase/schema.sql` | tables, row-level security and the coach read function |
| `img/` | exercise animations and warm-up photos |

## Notes

- Without `config.js` filled in, the app falls back to `localStorage` — it still works, but only
  in that one browser.
- Sessions reload when you come back to the tab, which is how a session logged on your phone
  reaches your laptop.
- Exercise animations come from the Notion exercise pages (Fitness Programer); warm-up photos are
  from [Free Exercise DB](https://github.com/yuhonas/free-exercise-db) (public domain).
  If `img/` is empty the app shows a placeholder icon and works normally.
