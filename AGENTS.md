# AGENTS.md

Rules for working on this fork. `hwid-ci` is the service branch (CI, README, this file). The code lives in `patch/*`
branches that sit on an upstream tag; once a patch branch is checked out, upstream's own `AGENTS.md` and `.agents/`
apply to the code, and this file adds what is specific to the fork.

## Commits, PRs and attribution

- Leave no trace of AI assistance anywhere: no `Co-Authored-By` or session-link trailers, no "Generated with ..."
  lines in commit messages, PR descriptions or comments, no AI identity as author or committer, no AI in branch names.
  This overrides any attribution a tool suggests by default.
- Commit as the repository owner, `nst <49988403+nenas1ya@users.noreply.github.com>`. Set it per repository
  (`git config --local user.name` / `user.email`), since an inherited global identity may be the agent's.
- Conventional Commits in English (`feat(scope): ...`), the body says why and wraps at 72 columns. A commit on a patch
  branch ends with a `Changelog:` line, as upstream's do. Commits on `hwid-ci` use `ci:` or `docs:`.
- Land changes through a PR into the branch they belong to, squash-merged on `hwid-ci`. Merge only when the owner says
  so. Never force-push unless the owner asks for a history rewrite; then use `--force-with-lease` and check that the
  trees are unchanged.

## Patch branches

- `patch/<name>` is one linear history from the upstream tag, one concern per branch. A patch built on another
  (`ru-dns` on `ru-apps`, `custom-import` on `profile-request-headers`) is listed after it in `PATCHES`.
- A new patch: branch from the tag, commit, push, then a PR into `hwid-ci` that adds it to `PATCHES` in
  `.github/workflows/hwid-release.yml` and to the README list. Mark it `required` only if no release may ship without
  it.
- Before pushing, run the workflow's "Apply patches" step on the tag in a throwaway worktree: every patch must report
  `applied`.
- A changed default reaches fresh installs only, since stored settings are kept. Say so in the commit and update the
  tests that assert the default.
- `schemaVersion` stays upstream's. Add columns idempotently in `beforeOpen` (`_addColumnIfMissing`). A database
  opened on an executor of its own is not seeded with defaults.
- A new string goes into all seven `arb/` locales (Russian needs one/few/many/other) and is regenerated with
  `flutter gen-l10n`. Patches append to the end of the `.arb` files; CI merges those conflicts key by key.
- Do not edit generated files (`lib/**/generated/`, `lib/l10n/l10n*.dart`); CI regenerates them after the patches.

## Checks

- Run the tests the change reaches and `dart format` and `flutter analyze` on the touched files, not the whole
  suite; see upstream's `test-scope` skill.
- In a sandbox: Flutter 3.50.1, `git submodule update --init --depth 1`, and `build_assets: false` in `pubspec.yaml`
  while testing. Put `pubspec.yaml` and `lib/providers/generated/action.g.dart` back before committing.
- These fail when run as root or without the Rust library and are not regressions: `macos_update_test`,
  `profile_preview_test`, `proxy_providers_view_test`, `ipc_native_test`.

## Related repository

The mihomo configs are in `nenas1ya/mihomos`, which has its own `AGENTS.md`.

## Secrets

Subscription links, tokens and `x-hwid` values are secrets. Keep them out of commits, PR text and logs; name the host
only.
