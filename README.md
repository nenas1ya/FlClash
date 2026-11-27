# FlClash + patches

Служебная ветка форка: только CI, workflow `hwid-release` и `dev-check`.

# Сборка релиза

Каждые 6 часов `hwid-release` берёт последний стабильный релиз https://github.com/chen08209/FlClash, накладывает
ветки-патчи из `PATCHES` и публикует сборку под тем же тегом `vX.Y.Z`, с файлом `FlClash-X.Y.Z-SHA256SUMS`.

* `required` - без патча релиз не собирается
* `optional` - если патч не накладывается на новый тег, сборка идёт без него, в описании релиза это отмечено
* Конфликты только в сгенерированных файлах не мешают: код перегенерируется после наложения патчей
* Платформы - Windows (setup.exe, zip), Linux (AppImage, deb, rpm), Arch (`flclash-hwid-*.pkg.tar.zst`), Android (apk)

Ручной запуск: Actions → hwid-release → Run workflow, можно указать тег апстрима, `force` пересобирает существующий
релиз.

## Патчи

* `patch/profile-request-headers` - свои заголовки запроса подписки, обязательный
* `patch/fork-updates` - проверка и скачивание обновлений из релизов форка, обязательный
* `patch/device-identity` - HWID и сообщения о лимите устройств
* `patch/ru-services` - Госуслуги, Сбер, VK, Яндекс, Кинопоиск в проверке сервисов
* `patch/ru-apps` - умный выбор российских приложений на Android

Ветки строятся от тега апстрима, по одной линейной истории на патч. Новые колонки базы патчи добавляют при открытии
(`_addColumnIfMissing` в `beforeOpen`), а не своей миграцией: номер `schemaVersion` остаётся апстримовым.

> [!note]
> `dev-check` по ручному запуску перегенерирует код в ветке-патче, пушит результат и гоняет analyze и тесты.

## Android

* С secrets `KEYSTORE`, `KEY_ALIAS`, `STORE_PASSWORD`, `KEY_PASSWORD` - подпись ключом форка, пакет `com.follow.clash`
* Без них - отладочный ключ, пакет `com.follow.clash.dev`
