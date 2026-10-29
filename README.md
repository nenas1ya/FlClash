# FlClash + patches

Служебная ветка форка. Здесь только CI: [`hwid-release`](.github/workflows/hwid-release.yml).

Каждые 6 часов workflow проверяет последний стабильный релиз [chen08209/FlClash](https://github.com/chen08209/FlClash), накладывает на него ветки-патчи из списка `PATCHES` и публикует сборку как релиз `vX.Y.Z-hwid` с `SHA256SUMS`.

- `required` — без этого патча релиз не собирается;
- `optional` — если патч не накладывается на новый тег, сборка идёт без него, в описании релиза это отмечено.

Платформы: Windows (setup.exe, zip), Linux (AppImage, deb, rpm), Arch (`flclash-hwid-*.pkg.tar.zst`, переупаковка deb), Android (apk).

Сейчас в `PATCHES`: `feat/profile-request-headers` (свои заголовки запроса подписки, обязательный), `feat/device-identity` (HWID и диалоги лимита), `feat/ru-services` (Госуслуги, Сбер, VK, Яндекс, Кинопоиск в проверках), `feat/ru-apps` (умный выбор российских приложений на Android).

Android подписывается ключом форка, если в secrets заданы `KEYSTORE`, `KEY_ALIAS`, `STORE_PASSWORD`, `KEY_PASSWORD`; без них — отладочным ключом с пакетом `com.follow.clash.dev`.

Ручной запуск: Actions → hwid-release → Run workflow (можно указать тег апстрима; `force` пересобирает существующий релиз).
