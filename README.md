# SafeDiary Converter

SafeDiary Converter — это утилита командной строки, предназначенная для извлечения данных из резервных копий дневника [SafeDiary](https://play.google.com/store/apps/details?id=ru.angryrobot.safediary) и конвертирования их в обычный текст.

## Сборка

Клонируйте репозиторий и используйте dub для сборки:

```sh
git clone https://github.com/Hekk0jdk/SafeDiary-Converter.git
cd SafeDiary-Converter
dub build --build=release
```

## Использование
Для простого использования укажите путь к файлу:
```sh
./convert -f SafeDiary-jan-1-2026.backup
```
### Флаги:
```sh
-f, --file      Путь к файлу
-t, --timezone  Изменение часового пояса (смещение по часам относительно UTC)
-l, --limit     Экспорт определенного количества записей (порядок не гарантируется, используется для тестов)
-h, --help      Помощь
```
