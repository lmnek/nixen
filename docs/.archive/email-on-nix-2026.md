# Email on Nix, August 2026

Research notes for adding declarative email to this repo. Versions verified by
`nix eval` against the nixpkgs rev pinned in `flake.lock`
(`104240a772`, nixos-unstable, 2026-08-03) and the home-manager rev
(`7834e825`). Everything else is cited or marked unverified.

## The short version

`accounts.email` in home-manager is the declarative layer. Declare an account
once; each client subscribes to it.

```nix
accounts.email.accounts.seznam = {
    address = "you@seznam.cz";
    flavor = "plain";                        # gmail.com presets hosts for you
    passwordCommand = [ "cat" "/home/lmnk/.config/mail/seznam" ];
    aerc.enable = true;
    thunderbird.enable = true;               # same data, second client
};
```

Recommended stack: **aerc daily + Thunderbird as GUI fallback, direct IMAP, no
mbsync, chmod-600 password files.** One file, `modules/home/mail.nix`.

## Clients with real `accounts.email` integration

Read from the pinned home-manager source, not docs:

aerc · thunderbird · neomutt · himalaya · meli · alot · astroid · notmuch ·
mbsync · msmtp · offlineimap · getmail · lieer · mujmap · mu · imapnotify

**No module: alpine.** That disqualifies it here regardless of merit — you'd
hand-roll `.pinerc` and wire three accounts through `incoming-folders` and
per-role SMTP manually.

## Package versions (verified locally)

| Package | Version | | Package | Version |
|---|---|---|---|---|
| aerc | 0.22.0 | | thunderbird | 153.0.1 |
| neomutt | 20260616 | | evolution | 3.60.2 |
| himalaya | 2.0.0 | | geary | 46.0 |
| meli | 0.8.13 | | claws-mail | 4.4.0 |
| alpine | 2.29.99 | | aerion | 0.3.2 |
| alot | 0.12 | | balsa | 2.6.5 |
| astroid | 0.17 | | mailspring | 1.23.0 |
| notmuch-bower | 1.1.1 | | kdePackages.kmail | 26.04.3 |
| matcha | 0.44.0 | | davmail | 6.8.1 |
| mblaze | 1.4 | | oama | 0.20.2 |
| isync | 1.5.1 | | pizauth | 1.1.0 |
| msmtp | 1.8.32 | | protonmail-bridge | 3.25.0 |
| notmuch | 0.40 | | hydroxide | 0.2.32 |
| goimapnotify | 2.5.7 | | neverest | 1.0.0-beta |
| cyrus-sasl-xoauth2 | 0.2 | | rdrview | 0.1.5 |

**Not in nixpkgs:** `betterbird` (dropped 2024-10-25, commit `544076a4a`;
re-adds [#375417](https://github.com/NixOS/nixpkgs/issues/375417) and
[#396383](https://github.com/NixOS/nixpkgs/issues/396383) closed as
not-planned), `sylpheed`, `trojita`, `stamp`, `sup`, `s-nail`, `mirador`.

## Per-account settings

**Seznam.cz** ([docs](https://o-seznam.cz/napoveda/email/postovni-programy-a-aplikace/),
cross-confirmed by [Mozilla ISPDB](https://autoconfig.thunderbird.net/v1.1/seznam.cz)):

- IMAP `imap.seznam.cz:993` SSL
- SMTP `smtp.seznam.cz:465` SSL/TLS, auth required
- Username = full email address. Covers seznam.cz / email.cz / post.cz.
- Plaintext connections being phased out. App password only if 2FA is on.

Also: `imap.seznam.cz:143` STARTTLS and `smtp.seznam.cz:587` STARTTLS work but
are undocumented. CalDAV/CardDAV at `caldav.seznam.cz` / `carddav.seznam.cz`.
One host serves all brands (cert SAN covers seznam.cz, email.cz, post.cz).

**Two widely-repeated claims about Seznam are false:**

- There is **no "enable IMAP" toggle.** Seznam's docs: POP3 and IMAP are
  *"trvale aktivní. Nelze je zcela vypnout"* — permanently on, cannot be
  disabled.
- OAuth2 is **advertised but unusable.** The servers offer `AUTH=XOAUTH2` and
  `AUTH=OAUTHBEARER`, but Seznam's developer scope list has **no mail scope** —
  identity only. Use password auth.

Auth: normal account password works without 2FA. With 2FA you need **one** app
password (*"Heslo pro aplikace"*, at Seznam Účet → Zabezpečení → Dvoufázové
ověření), which covers IMAP + SMTP + CalDAV together. Rotating your main
password does not rotate it. Forced browser logins after setup: **zero**.

**Quirks that will bite mbsync/aerc** (from live capability probes):

```
IMAP  CAPABILITY XLIST IMAP4rev1 AUTH=PLAIN AUTH=LOGIN AUTH=OAUTHBEARER
      AUTH=XOAUTH2 SASL-IR CHILDREN SORT I18NLEVEL=1 UIDPLUS ID MOVE UNSELECT
```

- **No `IDLE`.** `imapnotify` and aerc's idle will not work — poll only.
- **No `CONDSTORE`/`QRESYNC`/`NAMESPACE`** → no fast resync; every mbsync run
  does a full flag scan. Set `Path`/`PathDelimiter` explicitly.
- `UIDPLUS` and `MOVE` are present, so Trash/expunge handling is correct.
- `XLIST` but **no `SPECIAL-USE`** — clients keying off RFC 6154 `\Sent`/`\Trash`
  won't auto-detect. Folders are Czech: Doručené, Odeslané, Rozepsané, Hromadné,
  Archiv, Spam, Koš. Name them manually.
- **SMTP early-talker rejection:** a client sending `EHLO` before reading the 220
  banner gets `421 4.7.0 you are not welcome here`. Reads like an IP ban and will
  send you down the wrong debugging path. msmtp and aerc wait for the banner.
- POP3 has `LOGIN-DELAY 300` — 5-minute minimum between sessions.

**Not Seznam:** centrum.cz, atlas.cz, volny.cz, cbox.cz, mujmail.cz are
**Economia** — different infra, `AUTH=PLAIN` only, no IDLE, 25 MiB limit.

**Gmail** — `flavor = "gmail.com"` presets `imap.gmail.com` / `smtp.gmail.com`.
**App passwords still work** for IMAP/SMTP on personal accounts with 2-step
verification, and that's the shortest path by a wide margin.

If you ever want real OAuth on Gmail: register a Google Cloud "Desktop app"
client, and know that an app left in **Testing** publishing status issues
refresh tokens that **expire after 7 days**. Publishing it requires verification
for the restricted `https://mail.google.com/` scope. The common workaround is
reusing Thunderbird's baked-in client id/secret — works, not sanctioned.

## TUI clients

| | HM module | config | OAuth2 | needs mbsync? | verdict |
|---|---|---|---|---|---|
| **aerc** 0.22.0 | excellent | INI, fully generated | **native + refresh** | no | **pick this** |
| neomutt 20260616 | solid | generated rc | via `mutt_oauth2.py` | no, but you want it | most powerful, worst setup |
| alpine 2.29.99 | **none** | `.pinerc`, rewritten at runtime | yes, + Graph API | no | nostalgia |
| himalaya 2.0.0 | password-auth only | TOML | yes, you refresh | no | mid-refactor |
| meli 0.8.13 | maildir-only | TOML | external script | no | solo project |
| matcha 0.44.0 | none | undocumented | yes | no | pre-1.0, bookmark for 2027 |
| alot / astroid / notmuch-bower | yes | varies | n/a | **yes** | only after committing to notmuch |
| mblaze 1.4 | none | scripts | no | yes | toolbox, not a client |
| mutt-wizard 3.3.1 | none | imperative | no | yes | fights home-manager, skip |

**Why aerc wins.** It's the only client where all three pieces already exist:
native OAUTHBEARER/XOAUTH2 with **built-in refresh-token exchange** (set
`token_endpoint` and aerc treats the password as a refresh token and does the
exchange itself — no cron, no token daemon), `source-cred-cmd`/`outgoing-cred-cmd`
run under `sh -c` so nothing lands in the store, and a home-manager module that
models OAuth params as typed options and assembles the connection URL for you.

`withNotmuch` is on by default in the nixpkgs derivation, so moving from
IMAP-direct to mbsync+notmuch later is a config change, not a migration.

Release cadence: 0.20 (Jan 2025), 0.21 (Aug 2025), 0.22 (Jul 2026). 0.22 added
IMAP labels and `html-inline-images`.

**Alpine, properly.** nixpkgs ships Eduardo Chappa's fork from `repo.or.cz`, tag
`v2.29.99` — an *alpha*; most distros ship 2.26. It's genuinely maintained
(commits through June 2026) and has one unique superpower: a native **Microsoft
Graph** backend, which no other terminal client has.

The disqualifier isn't age, it's **mutability**. Alpine rewrites `~/.pinerc` at
runtime whenever you change a setting and manages `~/.pine-passfile` itself; the
docs say credentials cannot be pre-configured. A read-only store symlink breaks
it. You can push defaults via `/etc/pine.conf` and `/etc/pine.conf.fixed`, but
that's a hybrid with no module to help. Plus three accounts means manually
keeping `incoming-folders` + `folder-collections` + roles consistent, with no
concept of "an account" tying them together.

## Terminal HTML rendering

Ranked least-bad first:

1. **`w3m -dump -T text/html -I UTF-8 -O UTF-8 -cols 100`** — the correct
   default, what aerc ships, and the only one with a real table layout engine
   (which is what all marketing and transactional mail is built from). aerc's
   bundled `html` filter adds **network isolation** via `unshare --map-root-user
   --net`, so tracking pixels don't phone home. Renaming it to `html-unsafe`
   disables that.
2. **`elinks -dump -dump-color-mode 1 -no-references`** — underrated, the only
   dumper emitting ANSI color. Tables below w3m.
3. **`pandoc -f html -t plain`** — excellent on clean HTML (newsletters, GitHub
   notifications), falls apart on nested-table marketing mail.
4. `lynx -dump -nolist` — reliable, worst tables.
5. `html2text` — fast, tiny, output is 1998.

**The actual best trick:** `rdrview -T body -H | w3m -dump -T text/html`.
rdrview (0.1.5, packaged) is a Readability port — it strips nav/footer/tracking
cruft *before* rendering and turns most newsletters into something readable.

Inline images: w3m's own image support in nixpkgs is X11/framebuffer only, so
useless under niri. Use aerc 0.22's `html-inline-images = true` with `text/html=!
html -sixel` and `img2sixel` (from `libsixel` 1.10.5) — confirm ghostty does
sixel.

Opening in a real browser, via aerc's `[openers]`:

```ini
[openers]
text/html = zen-browser {}
x-scheme-handler/http* = zen-browser {}
```

`o`/`O` → `:open`, `<C-l>` → `:open-link`. With `html-inline-images = true`,
`:open` hands the browser a self-contained file with `cid:` images already
inlined as data URLs — renders correctly and offline.

## GUI clients

**Thunderbird 153.0.1 — the realistic pick.** The home-manager module (1277
lines) genuinely provisions accounts: `profiles.ini` plus a full `user.js` with
`mail.server.*` (IMAP or EWS), `mail.smtpserver.*`, `mail.identity.*` per
address *and per alias*, `calendar.registry.*` (CalDAV/ICS), `ldap_2.servers.*`
(CardDAV), `msgFilterRules.dat` per account, langpacks, enterprise `policies`,
userChrome. It has upstream tests including `thunderbird-office365.nix`.
OAuth2 is automatic: `xoauth2 → 10`, defaulted for gmail/office365 flavors.

153 opens OAuth login in your **default browser** rather than an embedded window
— good under niri. `MOZ_ENABLE_WAYLAND=1` is set by the nixpkgs wrapper.
Binary is in cache.nixos.org, so no Firefox-class local build.

Three real gotchas:

- **The module ignores `passwordCommand`** (zero references in the source). You
  log in by hand once per account. Thunderbird uses its own `key4.db`, not the
  system keyring.
- **`user.js` is a store symlink and wins at every startup.** Any pref you
  change in the GUI that the module also manages silently reverts on next
  launch. This is the thing that bites people.
- `remote.type = "google_calendar"` is a hard assertion failure — use `caldav`
  with `https://apidata.googleusercontent.com/caldav/v2/<ID>/events/`. CardDAV
  address books need a GUI round-trip first to generate a token.

Also packaged: `thunderbird-cli` and `thunderbird-mcp` (shell/agent access to a
running profile).

**Betterbird** would win on features — regex search, **diacritic-insensitive
search** (relevant for Czech), multi-line message list, minimize-to-tray, tracks
ESR monthly (140.13.0esr-bb25). But packaging it is on you.

**Geary — avoid.** No release since 46.0 (May 2024, which is why nixpkgs pins
there), unpatched CVE-2026-13324 open since June 2026, crash fixes sitting in
unreviewed MRs, no calendar at all, and OAuth delegated entirely to GNOME Online
Accounts — which doesn't run under niri. Disqualified on this machine.

**Claws Mail 4.4.0** — the only GUI client that *wants* to be configured from
files. Entire config tree is plain text (`clawsrc`, `accountrc`, `oauth2rc`),
and 4.4.0 moved OAuth2 provider definitions into `oauth2rc` with `protected=1`
to survive upgrades. Ugly UI, but most declarative GUI option.

**Aerion 0.3.2** — new (Go/Wails), active, in nixpkgs, handles Gmail + M365
OAuth + generic IMAP. But config is GUI-only by design ("modifying config files
directly is not recommended"), and reviewers report new-mail notifications don't
work. Bad fit for declarative.

**Stamp** — GTK4 on Evolution's engine, GNOME design + WebKit people
contributing, daily commits. Zero releases, zero tags, needs a patched
Evolution. Watch, don't deploy.

**Evolution 3.60.2** — `programs.evolution.enable` is a NixOS one-liner, and
`evolution-ews` gives the best Exchange/calendar/contacts story here. Closure
**2.21 GB**, but it's a fat GNOME-stack app, not a whole DE — runs fine
standalone under niri. Killer flaw: **accounts are wizard-only.**
`dconf.settings` holds UI prefs only; accounts live as GKeyFile
`~/.config/evolution/sources/<uid>.source` files that EDS writes back into, so
read-only store symlinks are fragile and the UIDs are opaque. Don't build on it.

**KMail / Kontact — bad idea under niri.** Closure 2.73/2.79 GB, and nixpkgs
Akonadi defaults to `backend = "mysql"`, i.e. a private **mariadb per user
session**. Akonadi resources are runtime agents with no declarative path.
Superb inside Plasma, wrong here.

**Not on Linux at all:** eM Client, Canary. **Mailspring** requires a cloud
account. **Bluemail** is an unfree snap blob with no maintainer.

Closures for scale: claws-mail 1.19 GB (smallest), geary 1.90 GB, evolution
2.21 GB, kmail 2.73 GB.

## Work / university (Microsoft 365)

Native EWS landed in Thunderbird 153 and there's an `outlook.office365.com-ews`
flavor plus an `account.ews` option in home-manager (added ~2026-04).

**But Microsoft disables EWS in Exchange Online from October 2026, fully off by
April 2027.** Thunderbird's Graph replacement is not implemented. So don't build
on EWS.

**DavMail 6.8.1 is the durable answer.** 6.8.0 (2026-06-12) added Graph mode, so
it outlives EWS retirement. Modes: `O365Graph`, `O365EWS`, `ExchangeEWS`,
`ExchangeWebDav`. Bridges Graph → IMAP/SMTP/CalDAV/CardDAV/LDAP locally, which
converts M365 into plain IMAP and sidesteps every client's OAuth weakness at
once. Config is a flat Java `.properties` file — trivially Nix-generated.

Two modules exist with **different schemas** — do not copy between them:

- NixOS `services.davmail`: `url` (required), `config` = **nested** attrset
- home-manager `services.davmail`: `settings` = **flat dotted** keys
  (`"davmail.imapPort" = 1143`), plus `imitateOutlook`, and it sets
  `davmail.oauth.tokenFilePath` to `$XDG_STATE_HOME` to keep tokens out of the
  store

There's also an `accounts.email` `davmail` flavor presetting `localhost:1143/1025`.

**Both Nix modules still default `davmail.url` to the EWS endpoint.** Override
to `davmail.mode = "O365Graph"` or it starts getting blocked October 2026.

Use `davmail.authentication = "O365Manual"` for the headless path — prints the
authorize URL, you log in on any browser and paste the code back. **Do not use
device-code flow**: Microsoft's new managed CA policies (auto-enabled ~45 days
after creation unless an admin opts out) include "Block device code flow", so
`oama --device` and `mutt_oauth2.py --authflow devicecode` now fail in most
corporate and university tenants. Much online advice is stale on this.

### How often M365 actually forces a browser login

Refresh tokens for public clients have a **90-day sliding inactivity window**,
not an absolute expiry — an hourly sync is three orders of magnitude inside it.
Default sign-in frequency is a rolling 90 days, i.e. no forced reauth. So:

| Situation | Browser logins/year |
|---|---|
| No CA sign-in-frequency policy | **0–2** (driven by password rotation) |
| CA sign-in frequency 30d / 7d | ~12 / ~52 |
| CA requires compliant / hybrid-joined device | **never works on Linux** |

What actually forces a browser: password change, SSPR, admin reset, explicit
revocation. Password *expiry* alone does not.

**Common misconception worth knowing:** an XOAUTH2 IMAP connection is *not*
"Other clients" — it classifies as a modern-auth desktop client. A vanilla
"block legacy authentication" CA policy does **not** break it.

Check protocol-level blocking first, before touching OAuth — no amount of OAuth
fixes `ImapEnabled $false`:

```powershell
Get-CASMailbox -Identity you@uni.edu | fl ImapEnabled,SmtpClientAuthenticationDisabled
```

Note IMAP and SMTP are independent toggles — **plenty of tenants disable IMAP but
leave Authenticated SMTP on.**

Microsoft never implemented OAUTHBEARER for IMAP/SMTP, only **XOAUTH2** — so use
aerc's `imaps+xoauth2://`, not its native `oauthbearer` scheme.

### The forwarding fallback — and its expiry date

I earlier called this the cheap durable option. Half of it is:

| Half | Status |
|---|---|
| Uni-side forwarding → personal Gmail (inbound) | **Unaffected, durable** |
| Gmail POP-fetching from the uni mailbox | **Dies January 2027** |
| Send-as a uni **M365** address from Gmail | **Dies January 2027** |
| Send-as a uni Google Workspace address | probably survives — Google's wording is ambiguous |

Google is removing "Send as" for third-party addresses and Gmailify/POP fetch in
January 2027. So plan it as: **forwarding for inbound (durable), and for outbound
run msmtp directly against the uni's SMTP with XOAUTH2** — which needs
`SmtpClientAuthenticationDisabled $false` but *not* IMAP.

Also note SMTP basic auth against M365 still works today, but is disabled by
default for existing tenants **end of December 2026** (admins can re-enable),
with final removal in H2 2027.

## OAuth2 tooling

- **`services.pizauth`** (home-manager module, pizauth 1.1.0, current with
  upstream) — best-supported path. Feeds msmtp via `passwordeval`, mbsync via
  `PassCmd`.
- **`oama` 0.20.2** — works, but no maintainer in nixpkgs, two versions behind,
  no module. Prefer pizauth.
- **aerc has OAuth built in** (native Go, `imaps+oauthbearer` / `xoauth2`, with
  `token_endpoint` / `client_id` params via `aerc.imapOauth2Params`). No
  override needed.
- **mbsync needs an override**: `pkgs.isync.override { withCyrusSaslXoauth2 =
  true; }`. Off by default and `programs.mbsync.package` has no awareness of it
  — silent-failure trap.
- `mutt_oauth2.py` ships in neomutt's **default** output; in mutt it's in the
  **`doc`** output only. Neither is wrapped for its Python deps.

## Secrets

**This machine already has a working Secret Service, via niri.**
`programs.niri.enable` sets `services.gnome.gnome-keyring.enable = lib.mkDefault
true` and routes `org.freedesktop.impl.portal.Secret` to gnome-keyring
(`nixos/modules/programs/wayland/niri.nix:46,74`). Verified live:
`gnome-keyring-daemon` owns `org.freedesktop.secrets` on the session bus,
`~/.local/share/keyrings/login.keyring` exists, PAM-unlocked at login. Nothing
in this repo references it — it comes transitively.

So the best option is the keyring, not a plaintext file:

```nix
passwordCommand = [ "secret-tool" "lookup" "email" "seznam" ];
```

Password encrypted at rest, unlocked by your login password, nothing plaintext
on disk. Add `pkgs.libsecret` (0.21.7) to get `secret-tool` — it's **not
currently on PATH**. One-time manual step per account:

```
secret-tool store --label="seznam" email seznam
```

Fallback, matching `modules/home/voxtype.nix:56` (chmod-600 file outside the
repo, nix store is world-readable):
`passwordCommand = [ "cat" "/home/lmnk/.config/mail/<account>" ]`.

No sops-nix or agenix in this repo; add one only if it ever goes public.

## Sync model

Start with **direct IMAP**. aerc speaks it natively; skipping local sync means
no isync config, no systemd timer, no msmtp, no notmuch.

Add mbsync when server-side search actually annoys you — it's additive, because
aerc's source is a one-line change between `imap://`, `maildir://`, and
`notmuch://`, and `accounts.email` already holds the account data.

For best-in-class search later: notmuch + mbsync + msmtp + astroid 0.17. Fully
declarative backend, unbeatable search, real GUI. Costs mandatory local sync and
no calendar.

## Gotchas

- `modules/home/mime.nix` owns `mimeapps.list` and has **no `mailto` entry** —
  `mailto:` links do nothing on this system today, independent of this project.
  Any client needs a line there.
- New modules must be hand-added to `modules/home/default.nix` imports; there is
  no auto-import.
- `just lint` runs deadnix — drop unused module arguments.
- Maildir would live on the `/home` btrfs subvolume; no impermanence, so `~/Mail`
  persists.

## Proton

`protonmail-desktop` 1.13.4 is packaged (Electron wrapper around the web app);
free tier works, zero declarability, no IMAP.

**Bridge is still paid-only** — Mail Plus, Unlimited, Duo, Family, Visionary, or
business. Free gets nothing. v3.25.0 (2026-06-01). Headless works
(`protonmail-bridge --cli`); `info` reads back the generated password and ports,
`cert export` gives you the cert for mbsync's `CertificateFile`.

Session persistence is **indefinite** — TOTP is consumed once at login and never
re-prompted. Vault (`vault.enc`, AES-GCM) holds the refresh token; the key lives
in your keyring. **A Bridge start that races ahead of keyring unlock used to
destroy the vault** (3.22.0 added retry logic) — order the unit after keyring
unlock anyway.

Two Nix modules, and the choice matters:

- **Prefer the NixOS `services.protonmail-bridge`** — uses `path`, which systemd
  prepends.
- The **home-manager one sets `Environment = [ "PATH=..." ]`, an absolute
  assignment** that wipes PATH to just `extraPackages`. Since Bridge probes
  `$PATH` for `pass`/gnome-keyring, that's a footgun.
- **Both bind `graphical-session.target`**; override with
  `lib.mkForce [ "default.target" ]` if headless.

**hydroxide is currently blocked, don't plan on it.** GitHub repo archived
2026-08-02, moved to Codeberg. Codeberg issue #328 (open since 2026-03-25):
Proton returns `[9001] "please complete CAPTCHA"`, confirmed by multiple users
on v0.2.32. A CLI can't satisfy it. Also broken: 2FA + two-password mode (#345),
long-lived sessions (#341), CardDAV (#347). **nixpkgs still fetches the archived
GitHub repo**, so it will silently lag. Avoid the `ferroxide` fork — it appears
to work by spoofing an app-version string, which is squarely "circumventing
security controls" under Proton's ToS §2.10.

**One clean win:** if you have a custom domain on a paid plan, **SMTP submission
tokens** (`smtp.protonmail.ch:587` STARTTLS, Settings → IMAP/SMTP → SMTP tokens,
shown once) give msmtp a send-only path with **no daemon, no keyring, no
browser**. Send-only; does nothing for reading.

## Forced browser logins per year, summarised

| Account | Mechanism | Logins/year |
|---|---|---|
| Gmail personal, 2FA on | **app password** | **0**, indefinitely |
| Gmail personal, OAuth published "In production" | self-registered client | ~0 |
| Gmail personal, OAuth left in "Testing" | 7-day refresh token | **~52** |
| Seznam | password / one app password | **0**, forever |
| M365, no CA sign-in-frequency policy | OAuth | 0–2 |
| M365, CA sign-in frequency 30d / 7d | OAuth | ~12 / ~52 |
| M365, CA requires compliant device | — | **never works on Linux** |
| Proton paid | Bridge vault persists | 0 |
| Proton free | hydroxide | **currently blocked** |

## Not verified

- Whether a university **Google Workspace** send-as address survives Gmail's
  January 2027 third-party send-as removal (Google's wording is ambiguous)
- Seznam's literal Czech folder wire names / delimiter — check with `mbsync -l`
  on first run
- Whether Seznam's SMTP writes a server-side Sent copy — test one send before
  configuring fcc, or you may get duplicates
- DavMail's author has published no explicit statement about the October 2026
  EWS cutoff; "Graph is the migration path" is drawn from code and release notes

## Recommended for this machine

### Phase 1 — do this now

**aerc + Thunderbird, direct IMAP, secret-tool, three accounts, one file.**

| Decision | Choice | Why |
|---|---|---|
| TUI client | **aerc 0.22.0** | Only client where the HM module, native OAuth refresh, and `source-cred-cmd` all already exist |
| GUI fallback | **Thunderbird 153.0.1** | ~3 extra lines; covers aerc's weak spots (HTML mail, calendar invites, bank PDFs) |
| Sync | **Direct IMAP, no mbsync** | Skips isync + msmtp + notmuch + a systemd timer. Seznam has no QRESYNC anyway, so local sync buys less than usual |
| Secrets | **`secret-tool`** | gnome-keyring already runs and is PAM-unlocked; nothing plaintext on disk |
| Seznam | password, or one app password if 2FA | Zero browser logins, forever |
| Gmail ×2 | **app passwords** | Not deprecated, no expiry, one string each. Don't build an OAuth pipeline you don't need |

Files touched: new `modules/home/mail.nix`, one line in
`modules/home/default.nix` imports, one `mailto` entry in
`modules/home/mime.nix`, `pkgs.libsecret` for `secret-tool`. ~60 lines.

### Phase 2 — only if phase 1 sticks

Add **mbsync + notmuch** when server-side search actually annoys you. aerc's
`withNotmuch` is already on and its source is a one-line change, so this is a
config edit, not a migration.

### Work / university — decision tree

1. Check `ImapEnabled` and `SmtpClientAuthenticationDisabled` **first**. No
   amount of OAuth fixes a protocol-level block, and they're independent.
2. IMAP on → **aerc with `imaps+xoauth2://` + `services.pizauth`**. Expect one
   admin-consent request. Realistically 0–2 browser logins/year.
3. IMAP off, SMTP on → **forwarding inbound + msmtp outbound**. Cheapest real
   option.
4. Both off, or CA requires a compliant device → **DavMail in
   `davmail.mode = "O365Graph"`** (not the EWS default), or give up on direct
   access.

Don't build on native EWS — blocked from October 2026.

### Skip

- **Alpine** — rewrites `.pinerc` at runtime; structurally hostile to a flake
- **Geary** — unpatched CVE, dead since 2024, needs GOA you don't run
- **KMail** — mariadb per user session under niri
- **Betterbird** — would be the best GUI, but you'd maintain the package
- **Proton** — bridge needs a paid plan; hydroxide is CAPTCHA-blocked
- **matcha** — pre-1.0, no module, undocumented config. Revisit in 2027

### Open questions only you can answer

- Gmail app passwords — already generated, or need the walkthrough?
- Is the work account M365 or Google Workspace? Changes the whole branch above.
