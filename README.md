# FlClash + patches

Service branch of the fork: CI only, the `hwid-release` and `dev-check` workflows.

# Release build

Every 6 hours `hwid-release` takes the latest stable release of https://github.com/chen08209/FlClash, applies the
patch branches listed in `PATCHES` and publishes the build under the same `vX.Y.Z` tag, with a
`FlClash-X.Y.Z-SHA256SUMS` file.

* `required` - no release is built without the patch
* `optional` - if the patch does not apply to a new tag, the build goes on without it and the release notes say so
* Conflicts only in generated files do not count: the code is regenerated after the patches are applied
* Conflicts in `arb/*.arb` are merged key by key, since patches append their strings to the end of those files
* Platforms - Windows (setup.exe, zip), Linux (AppImage, deb, rpm), Arch (`flclash-hwid-*.pkg.tar.zst`), Android (apk)

Manual run: Actions → hwid-release → Run workflow. An upstream tag can be given, `force` rebuilds an existing release.

## Patches

* `patch/profile-request-headers` - custom request headers for subscriptions, required
* `patch/fork-updates` - check for and download updates from the fork's releases, required
* `patch/device-identity` - HWID and device limit messages
* `patch/ru-services` - Gosuslugi, Sber, VK, Yandex and Kinopoisk in the service check; Russian services in the default
  bypass domains
* `patch/service-status-count` - how many services the dashboard shows
* `patch/ru-apps` - smart selection of Russian apps on Android; they bypass the VPN by default
* `patch/ru-dns` - Cloudflare and Quad9 DoH for profiles without DNS, `.ru`/`.su`/`.рф` through Yandex; DNS hijacking
  on by default (built on top of `patch/ru-apps`)
* `patch/global-rules-import` - added rules as text (quick edit) and import from the `rules:` of a config by URL
* `patch/default-rules` - a new install starts with proxy loopback blocked and LAN and BitTorrent direct

Branches start from the upstream tag, one linear history per patch. Patches add new database columns when the database
opens (`_addColumnIfMissing` in `beforeOpen`), not with a migration of their own: `schemaVersion` stays the upstream
one.

> [!note]
> `dev-check`, run manually, regenerates the code in a patch branch, pushes the result and runs analyze and the tests.

## Android

* With the `KEYSTORE`, `KEY_ALIAS`, `STORE_PASSWORD`, `KEY_PASSWORD` secrets - signed with the fork's key, package
  `com.follow.clash`
* Without them - debug key, package `com.follow.clash.dev`
