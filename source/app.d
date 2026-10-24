import std.array : array;
import std.algorithm.iteration : map;
import std.file : read, write, exists, mkdir, remove;
import std.getopt : getopt, defaultGetoptPrinter;
import std.zip;
import d2sqlite3;
import time : unix_to_datetime;

enum tmp_file = "diary.db";
enum dir_name = "export";
immutable string[] mood = [
    "Отличное настроение",
    "Хорошее настроение",
    "Нормальное настроение",
    "Плохое настроение",
    "Ужасное настроение",
];


struct Data
{
private:
    CachedResults dates, moods, texts, tags;
    long len;

    string format_data(int i)
    {
        string res;
        static immutable string format_content = "%s\n\n%s\n%s\n\n";

        import std.json;
        import std.array : join;
        import std.format : format;
        import arsd.htmltotext : htmlToText;

        auto j = parseJSON(tags[i][0].as!string);
        auto tgs = j.array.map!(s => "#" ~ s.str).join(" ");
        res = format(format_content, htmlToText(texts[i][0].as!string), mood[moods[i][0].as!byte], tgs);

        return res;
    }

public:
    void parse_data()
    {
        auto db = Database(tmp_file);
        dates = db.execute("SELECT date FROM diary_entries ORDER BY id").cached;
        moods = db.execute("SELECT mood FROM diary_entries ORDER BY id").cached;
        texts = db.execute("SELECT c0text FROM diary_entries_text_content ORDER BY docid").cached;
        tags = db.execute("SELECT c1tags FROM diary_entries_text_content ORDER BY docid").cached;
        len = dates.length;
    }

    void write_to_file(byte timezone, long limit)
    {
        import std.path : buildPath;

        if (!exists(dir_name))
            mkdir(dir_name);

        for (int i = 0; i < len; i++) {
            if (i >= limit) break; // For tests
            string note_name = unix_to_datetime(dates[i][0].as!long, timezone);
            string content = format_data(i);

            auto path = buildPath(dir_name, note_name);
            write(path, content);
        }
    }
}

void extract_database(string backup_path)
{
    auto zip = new ZipArchive(read(backup_path));
    foreach (am; zip.directory) {
        if (am.name == "diary_database"){
            auto buf = zip.expand(am);
            write(tmp_file, buf);
        }
    }
}

void main(string[] args)
{
    string backup_path;
    byte tz = 0;
    long limit = long.max;

    auto info = getopt(
        args,
        "file|f", "backup path", &backup_path,
        "timezone|t", "UTC offset in hour", &tz,
        "limit|l", "export at most N notes (for testing)", &limit,
    );

    if (info.helpWanted || !backup_path) {
        defaultGetoptPrinter("Convert safe-diary backups to plain text", info.options);
        return;
    }

    if (!exists(backup_path)) {
        import std.stdio : writeln;
        writeln("Not found backup file");
        return;
    }

    extract_database(backup_path);
    scope(exit) if (exists(tmp_file)) remove(tmp_file);

    auto d = new Data;
    d.parse_data();
    d.write_to_file(tz, limit);
}
