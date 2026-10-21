module time;

import std.stdio : writeln;
import std.format : format;

private enum string datef = "%d.%02d.%02d-%02d:%02d:%02d";

private struct Date {
    int y, m, d, h, mn, s;

    pure string as_str() {
        return format(datef, y, m, d, h, mn, s);
    }
}

pure string unix_to_datetime(long unixt, byte timeshift)
{
    Date date;

    // temp data
    bool is_leap;
    int d;
    short y = 1970, m;
    int seconds_day;
    static immutable short[12] month_len = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    //

    unixt /= 1000;
    unixt += timeshift * 3600;

    seconds_day = unixt % 86_400;
    d = cast(int)(unixt / (24 * 60 * 60));

    while (true) {
        // Високосный год
        is_leap = ((y % 4 == 0 && y % 100 > 0) || (y % 400 == 0));
        const short days_in_years = 365 + cast(short)is_leap;

        if (d >= days_in_years) {
                y += 1;
            d -= days_in_years;
        } else {
            break;
        }
    }

    foreach (i, len ; month_len) {
        // Февраль
        int rlen = (is_leap && i == 1) ? 29 : len;

        if (d >= rlen) {
            m += 1;
            d -= rlen;
        } else {
            break;
        }
    }

    date.y = y;
    date.m = m + 1;
    date.d = d + 1;
    date.h = seconds_day / 3600;
    date.mn = (seconds_day % 3600) / 60;
    date.s = seconds_day % 60;

    return date.as_str();
}

unittest {
    assert(unix_to_datetime(1_791_489_570_036, 4) == "2026.10.08-23:59:30");
    assert(unix_to_datetime(1_720_806_033_337, -2) == "2024.07.12-15:40:33");
}
