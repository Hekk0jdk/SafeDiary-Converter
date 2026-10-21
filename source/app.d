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
        dates = db.execute("SELECT date FROM diary_entries").cached;
        moods = db.execute("SELECT mood FROM diary_entries").cached;
        texts = db.execute("SELECT text FROM diary_entries_text").cached;
        tags = db.execute("SELECT tags FROM diary_entries_text").cached;
        len = dates.length;
    }

    void write_to_file()
    {
        import std.path : buildPath;

        if (!exists(dir_name))
            mkdir(dir_name);

        for (int i = 0; i < len; i++) {
            string note_name = unix_to_datetime(dates[i][0].as!long, 4);
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

        auto buf = zip.expand(am);
        write(tmp_file, buf);
    }
}

void main(string[] args)
{
    string backup_path;

    auto info = getopt(
        args,
        "file|f", "backup path", &backup_path,
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

    auto d = new Data;
    d.parse_data();
    d.write_to_file();

    remove(tmp_file);
}
