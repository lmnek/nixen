# Setup

Post-install steps to run after deploying this NixOS configuration.

## 1. Change user password

```sh
sudo passwd lmnk
```

## 2. Install fish plugins

Install fisher, then use it to manage plugins:

```fish
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

## 3. Install yazi plugins

```sh
ya pkg install
```

## 4. Grant permissions to zellij plugins

```sh
zellij plugin -- https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm
```

## 5. Bootstrap Zen

Spaces live in `zen-sessions.jsonlz4` and keyboard shortcuts in
`zen-keyboard-shortcuts.json`. Zen creates both on first launch, so on a fresh
profile they do not apply until that launch has happened:

```sh
nixos-rebuild switch                          # creates the profile, no state files yet
zen                                           # launch once to create them, then quit
systemctl restart home-manager-lmnk.service   # Zen closed, so activation re-runs and writes them
zen                                           # reopen: spaces and shortcuts are there
```

`restart` rather than a second `switch`, because the writer only runs when the
generation changes and an unchanged switch is a no-op.

Afterwards, close Zen before any `switch` that touches spaces, containers or
shortcuts. The activation script needs exclusive access to those files and
skips them with a warning while Zen is running, without failing the switch.

## 6. Email accounts

Two things live outside this repo: the identity file and the passwords. The
identity file must exist first, or the build fails.

```sh
mkdir -p ~/.config/nixen-private
$EDITOR ~/.config/nixen-private/identity.nix
```

```nix
{
    realName = "Your Name";
    seznam = "you@seznam.cz";
    gmailMain = "you@gmail.com";
    gmailAlt = "other@gmail.com";
}
```

Attribute names must match what `modules/home/mail.nix` reads. Re-lock after
every edit — `flake.lock` pins the file by hash, so without it Nix keeps the old
values and says nothing:

```sh
cd ~/repos/nixen && nix flake update private && just switch
```

Gmail needs an app password (basic auth is gone), and those exist only on
accounts with 2-Step Verification. Turn 2SV on at
<https://myaccount.google.com/signinoptions/twosv>, then create one password per
account at <https://myaccount.google.com/apppasswords>, signed in as that
account. "The setting you are looking for is not available for your account"
means 2SV is still off; rarer causes are Advanced Protection or a Workspace
admin block. Seznam uses its normal password.

Store them — paste the 16 characters without the spaces Google shows, the last
two words of each line are the lookup key and must match `mail.nix`, `--label`
is cosmetic:

```sh
secret-tool store --label=seznam     email seznam
secret-tool store --label=gmail-main email gmail-main
secret-tool store --label=gmail-alt  email gmail-alt
```

Verify with `secret-tool lookup email gmail-main`, then start `aerc`. Passwords
are read at launch, so changing one needs no rebuild: store it again and restart
aerc.
