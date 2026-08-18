# Per-repo GitHub identity (fixes the recurring 403 problem)

You hit this twice today: `gh`'s "active account" doesn't match the account
that owns the repo you're pushing to, so you get `Permission ... denied to
<wrong-account>`. The usual fix (`gh auth switch`) works but you have to
remember to do it every time you move between projects for different
GitHub accounts.

This makes it automatic: git picks the right identity and credentials
based on which folder you're in, regardless of whatever `gh`'s "active"
account happens to be.

## How it works

1. `~/.gitconfig` gets one `[includeIf "gitdir:..."]` block per project
   folder (or per parent folder covering several projects for the same
   client/account).
2. Each block points at a small per-account config file that sets:
   - `user.name` / `user.email` — so commits are attributed correctly
   - `credential.https://github.com.helper` — pointed at
     `gh-credential-helper.sh`, a small wrapper around
     `gh auth token --user <name>`. This is necessary because `gh`'s own
     credential helper (`gh auth git-credential`) has a known bug
     ([cli/cli#9111](https://github.com/cli/cli/issues/9111)): it ignores
     the account username git asks for and always serves whichever
     account is currently "active," so a naive `credential.username`
     override doesn't actually work — git falls back to an interactive
     password prompt instead. The wrapper script sidesteps this by calling
     `gh auth token --user <name>` directly, which does correctly fetch a
     specific non-active account's token.

## Setup

1. Copy the account file(s) you need into your home directory. One
   confirmed example is included — `claude-session-monitor` already
   pushes as `achint-gupta-tech`, so this repo's config is known-correct:

   ```
   cp ~/Developer/claude-session-monitor/git-identity/.gitconfig-achint-gupta-tech.example ~/.gitconfig-achint-gupta-tech
   ```

   Edit that file and fill in the real email address for that account
   (`git config --global user.email` won't tell you this — check
   github.com → Settings → Emails while logged into that account, or use
   the `<username>@users.noreply.github.com` no-reply address instead if
   you'd rather not expose your real email in commits).

2. For your other four accounts (`corriente-app`, `achint-prog`,
   `biznetworx-uae`, `ruvofin-solutions`), duplicate that file per
   account, e.g.:

   ```
   cp ~/.gitconfig-achint-gupta-tech ~/.gitconfig-corriente-app
   ```
   then edit `user.name`, `user.email`, and the username argument passed
   to `gh-credential-helper.sh` inside it to match that account.

3. Append matching `includeIf` blocks to `~/.gitconfig` — see
   `gitconfig-includeif.example` in this folder for the exact syntax.
   One block per project folder (or a parent folder if several repos
   belong to the same client/account). Trailing slashes on the `gitdir:`
   path matter — don't drop them.

4. Test it without pushing anything:
   ```
   cd ~/Developer/claude-session-monitor
   git config user.email
   git config credential.https://github.com.username
   ```
   Should print `achint-gupta-tech`'s email and username — confirming
   this folder resolves to the right identity before you ever run
   `git push`.

## Note

This doesn't require any of the five accounts to be "active" in `gh` —
each repo resolves its own account independently. You should never need
`gh auth switch` again once every project folder has a matching block.
