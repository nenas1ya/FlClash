# FlClash + patches

Служебная ветка форка. Здесь только CI: [`hwid-release`](.github/workflows/hwid-release.yml).

Каждые 6 часов workflow проверяет последний стабильный релиз [chen08209/FlClash](https://github.com/chen08209/FlClash), накладывает на него ветки-патчи из списка `PATCHES` и публикует сборку как релиз `vX.Y.Z-hwid` с `SHA256SUMS`.

- `required` — без этого патча релиз не собирается;
- `optional` — если патч не накладывается на новый тег, сборка идёт без него, в описании релиза это отмечено.

Android собирается, только если в secrets заданы `KEYSTORE`, `KEY_ALIAS`, `STORE_PASSWORD`, `KEY_PASSWORD`.

Ручной запуск: Actions → hwid-release → Run workflow (можно указать тег апстрима).
