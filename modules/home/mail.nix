# Email. `accounts.email` declares each account once and aerc reads from
# there, so adding a second client later needs no retyping.
#
# Direct IMAP, no mbsync/notmuch. aerc speaks IMAP itself, and Seznam
# advertises neither QRESYNC nor CONDSTORE, so a local sync would rescan every
# flag on each run. To go offline later, point aerc's source at maildir:// and
# add programs.mbsync.
#
# This repo is public, so two things stay out of it. Passwords live in
# gnome-keyring, which niri enables and PAM unlocks at login. Name and
# addresses live in ~/.config/nixen-private/identity.nix, because Nix reads
# them while evaluating and nothing can reach the keyring that early.
# Step 6 of docs/SETUP.md covers a first-time or second-machine setup.
{ pkgs, inputs, ... }:

let
    # flake.lock pins this file by hash, so editing it changes nothing until
    # `nix flake update private` runs. Nix keeps using the old values.
    identity = import "${inputs.private}/identity.nix";

    # ponytail: keyring over a chmod-600 file. Encrypted at rest, unlocked by
    # the login password, and read at runtime, so no password becomes a Nix
    # value or reaches the world-readable store.
    secret = name: [ "secret-tool" "lookup" "email" name ];

    # `:open` works only in the viewer, so reaching the HTML part from the
    # message list means piping the raw message somewhere. Python's email module
    # does the MIME walk, the transfer decoding and the charset conversion.
    #
    # Bound to `O` rather than made the default, because a real browser fetches
    # remote images and so tells the sender the mail was opened.
    openHtml = pkgs.writers.writePython3Bin "aerc-open-html" { } ''
        import base64
        import email
        import email.policy
        import os
        import subprocess
        import sys
        import tempfile

        msg = email.message_from_binary_file(
            sys.stdin.buffer, policy=email.policy.default
        )
        part = msg.get_body(preferencelist=("html",))
        if part is None:
            sys.exit("no text/html part in this message")
        html = part.get_content()

        # Inline images arrive as sibling parts the HTML points at by
        # Content-ID. A file:// page has no way to resolve cid:, so a logo or
        # a newsletter banner renders as a broken icon unless it is folded
        # into the document. aerc does this itself, but only for parts it
        # fetches; :pipe -m hands over the raw message untouched.
        #
        # ponytail: substring replace per part, no HTML parse and no regex.
        # Walking the parts we have is cheaper than finding the references,
        # and an unmatched cid: is left alone, exactly as it renders today.
        for sub in msg.walk():
            cid = sub["Content-ID"]
            if not cid:
                continue
            data = base64.b64encode(sub.get_payload(decode=True)).decode()
            url = f"data:{sub.get_content_type()};base64,{data}"
            html = html.replace("cid:" + cid.strip("<>"), url)

        # XDG_RUNTIME_DIR is tmpfs, mode 0700, so the body never lands in /tmp
        # or on disk. Nothing deletes the file. The browser still needs it
        # after this exits, and logout clears the directory.
        fd, path = tempfile.mkstemp(
            suffix=".html", dir=os.environ["XDG_RUNTIME_DIR"]
        )
        os.write(fd, html.encode())
        os.close(fd)
        # noqa: writePython3Bin runs flake8, which counts the store path.
        opener = "${pkgs.xdg-utils}/bin/xdg-open"  # noqa: E501
        subprocess.run([opener, path], check=False)
    '';

    # aerc polls nothing by default (check-mail = 0). Gmail pushes over IDLE
    # regardless, but Seznam advertises no IDLE, so on that account this is the
    # only thing that notices new mail.
    #
    # `archive` has no accounts.email option, and aerc's default of `Archive`
    # exists on neither provider, so :archive needs the name passed in.
    aercAccount = archive: {
        enable = true;
        extraAccounts = {
            check-mail = "5m";
            inherit archive;
            # Without this the sidebar is plain alphabetical, and Go compares
            # bytes, so every capitalised folder outranks INBOX. Anything
            # unlisted still follows alphabetically.
            folders-sort = "INBOX";
        };
    };

    # The gmail.com flavor sets hosts and ports only, leaving folders at the
    # generic names that Gmail's IMAP does not have.
    gmail' = name: address: {
        inherit address;
        inherit (identity) realName;
        flavor = "gmail.com";
        passwordCommand = secret name;
        folders = {
            # ponytail: empty sent makes aerc omit copy-to. Gmail's SMTP files
            # sent mail on the server, so copying it back would duplicate it.
            sent = "";
            drafts = "[Gmail]/Drafts";
        };
        aerc = aercAccount "[Gmail]/All Mail"; # Gmail archives by dropping INBOX
    };
in
{
    accounts.email.accounts = {
        seznam = {
            primary = true;
            address = identity.seznam;
            userName = identity.seznam; # Seznam wants the full address
            inherit (identity) realName;
            passwordCommand = secret "seznam";

            imap.host = "imap.seznam.cz"; # 993 implicit TLS (module default)
            smtp = {
                host = "smtp.seznam.cz";
                port = 465;
                tls.useStartTls = false;
            };

            # Seznam uses lowercase names, and aerc resolves folder roles only
            # for JMAP, so webmail's Czech labels are not what goes here.
            folders = {
                sent = "sent";
                drafts = "drafts";
            };

            aerc = aercAccount "archive";
            };

        # home-manager writes the primary account first, then the rest by
        # attribute name (aerc/default.nix:187), and aerc tabs follow
        # accounts.conf. So the names have to sort into the order the `,`
        # binds below claim. `gmail` < `gmail-alt`; `gmail-main` did not.
        # The argument is the keyring key, so renaming costs no secret-tool run.
        gmail = gmail' "gmail-main" identity.gmailMain;
        gmail-alt = gmail' "gmail-alt" identity.gmailAlt;
    };

    programs.aerc = {
        enable = true;
        extraConfig = {
            general.unsafe-accounts-conf = true; # accounts.conf is a store symlink
            ui = {
                sidebar-width = 22;
                keyhint = true; # which-key style popup after a prefix key
                mouse-enabled = true; # click and scroll wheel; off by default

                # Off by default, and neither server threads for us: Gmail has
                # THREAD=REFERENCES but Seznam's CAPABILITY has no THREAD, so
                # aerc builds the tree client-side there.
                threading-enabled = true;
                # Nests Gmail's [Gmail]/* under one node. dirlist-collapse
                # would fold them shut; its default of 0 leaves them open.
                dirlist-tree = true;
                # vim's scrolloff. Default 0 parks the cursor on the last row.
                msglist-scroll-offset = 3;
            };

            compose = {
                empty-subject-warning = true;
                # Go regexp, (?im) implied. `^[^>]*` skips quoted lines, so a
                # reply to someone else's "attached" does not trip it. Czech
                # stems cover příloha/příloze/přílohu and přikládám.
                no-attachment-warning = "^[^>]*(attach(ed|ment)|příloh|přiklád)";
            };

            viewer = {
                # HTML first; <C-k> steps back to the plaintext part.
                alternatives = "text/html,text/plain";
                # aerc has no pager of its own; without this it takes $PAGER,
                # whatever the shell happened to export. -R passes the filters'
                # ANSI colour through.
                pager = "less -Rc";
            };

            # aerc never merges its own defaults in, so an unlisted type gets
            # no rendering, only open/save/pipe. colorize and calendar ship in
            # aerc's libexec, already on the filter PATH.
            filters = {
                "text/plain" = "colorize";
                "text/calendar" = "calendar";
                "message/delivery-status" = "colorize";
                "message/rfc822" = "colorize";
                # aerc's own filter rather than a hand-rolled w3m call. It runs
                # w3m under `unshare --net`, so tracking pixels cannot call out.
                # `html-unsafe` is the same filter with networking left on.
                #
                # ponytail: no `!` prefix, so output goes to less rather than
                # w3m's pager, which only walks a cursor line by line. aerc
                # scrapes links out of the filter output for :open-link (<C-l>),
                # so w3m's interactive mode buys nothing.
                "text/html" = "html | colorize";
            };
        };

        # `,` leads to the account tabs, staying clear of Alt (herdr's layer).
        # :ct takes an index too, but opening a message adds a tab and shifts
        # every later index, so bind the names. Text after ` # ` is the keyhint
        # label.
        #
        # Appending upstream's binds.conf is required. aerc installs its own
        # only when none exists (config/binds.go), so this file becomes the
        # entire keymap and Ctrl+n and friends would vanish. Global binds skip
        # compose and the terminal, which set $noinherit.
        extraBinds = ''
            u = :filter -u<Enter> # Unread only (<Esc> clears)
            O = :pipe -b -m ${openHtml}/bin/aerc-open-html<Enter> # Open HTML in browser
            <C-r> = :check-mail<Enter> # Check mail now (not R: Rr/Rq reply)
            tr = :read -t<Enter> # Toggle read
            ts = :flag -t<Enter> # Toggle flagged
            ta = :flag -t -a<Enter> # Toggle answered
            ,1 = :ct seznam<Enter> # seznam
            ,2 = :ct gmail<Enter> # gmail
            ,3 = :ct gmail-alt<Enter> # gmail-alt
            ,, = :ct -<Enter> # Back to last tab
        '' + builtins.readFile "${pkgs.aerc}/share/aerc/binds.conf";
    };

    # secret-tool comes from libsecret. The html filter carries its own w3m.
    home.packages = [ pkgs.libsecret ];
}
