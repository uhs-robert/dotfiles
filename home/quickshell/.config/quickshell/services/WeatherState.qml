// home/quickshell/.config/quickshell/services/WeatherState.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// One shared Open-Meteo fetch for every bar. Ported from the Waybar Ruby weather
// script (get_weather.rb) so the module has no Ruby dependency.
Singleton {
    id: root

    readonly property var default_settings: ({
        latitude: "auto",
        longitude: "auto",
        unit: "fahrenheit",
        time_format: "24h",
        days: 7
    })

    property var settings: default_settings

    property var current: null
    property var hours: []
    property var days: []
    property string location_name: ""
    property double updated: 0
    property string sunrise: ""
    property string sunset: ""
    property var moon: ({ phase: 0, name: "" })

    property bool has_data: false
    property bool loading: false
    property bool stale: false
    property string error: ""

    property double last_success_ms: 0
    property bool warned_once: false
    property double last_attempt_ms: 0
    property int utc_offset: 0

    readonly property int refresh_interval_ms: 900000
    readonly property int request_timeout_ms: 10000
    readonly property int min_refresh_gap_ms: 60000
    readonly property int retry_gap_ms: 120000

    FileView {
        id: settings_file
        path: Quickshell.shellDir + "/weather.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                const changed = root.has_data && JSON.stringify(root.settings) !== JSON.stringify(Object.assign({}, root.default_settings, parsed));
                root.settings = Object.assign({}, root.default_settings, parsed);
                if (changed) root.refresh(true);
            } catch (e) {
                console.warn("Weather: invalid weather.json, keeping last config (" + e + ")");
            }
        }
        onLoadFailed: error => console.warn("Weather: failed to load weather.json (" + error + "), using defaults")
    }

    readonly property string cache_dir: {
        const xdg = Quickshell.env("XDG_CACHE_HOME");
        const base = xdg && xdg !== "" ? xdg : (Quickshell.env("HOME") + "/.cache");
        return base + "/quickshell";
    }

    Process {
        id: ensure_cache_dir
        command: ["mkdir", "-p", root.cache_dir]
    }

    FileView {
        id: cache_file
        path: root.cache_dir + "/weather.json"
        blockLoading: true
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed.settings_key !== JSON.stringify(root.settings)) return;
                root.apply_data(parsed);
                root.last_success_ms = parsed.updated || 0;
            } catch (e) {
                console.warn("Weather: invalid cache file (" + e + ")");
            }
        }
        onLoadFailed: error => {}
    }

    Component.onCompleted: {
        ensure_cache_dir.running = true;
        settings_file.reload();
        cache_file.reload();
        root.refresh_if_due();
    }

    // Checks every minute so the refresh follows the data's age, not process uptime.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh_if_due()
    }

    function refresh_if_due() {
        const now = Date.now();
        if (now - root.last_success_ms >= root.refresh_interval_ms && now - root.last_attempt_ms >= root.retry_gap_ms) root.refresh(true);
    }

    // A non-forced call within min_refresh_gap_ms of the last success is a no-op.
    function refresh(force) {
        if (root.loading) return;
        const now = Date.now();
        if (!force && root.last_success_ms > 0 && (now - root.last_success_ms) < root.min_refresh_gap_ms) return;
        root.loading = true;
        root.last_attempt_ms = now;
        root.start_fetch();
    }

    function start_fetch() {
        const lat = root.settings.latitude;
        const lon = root.settings.longitude;
        if (String(lat) === "auto" || String(lon) === "auto") {
            root.fetch_location();
        } else {
            root.fetch_forecast(root.parse_num(lat, 0), root.parse_num(lon, 0), "");
        }
    }

    function fetch_location() {
        const xhr = new XMLHttpRequest();
        xhr.timeout = root.request_timeout_ms;
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const name = [data.city, data.regionName, data.country].filter(p => !!p).join(", ");
                    root.fetch_forecast(root.parse_num(data.lat, 0), root.parse_num(data.lon, 0), name);
                } catch (e) {
                    root.fail("location parse error: " + e);
                }
            } else {
                root.fail("location request failed: " + xhr.status);
            }
        };
        xhr.onerror = () => root.fail("location request network error");
        xhr.ontimeout = () => root.fail("location request timed out");
        xhr.open("GET", "http://ip-api.com/json/?fields=lat,lon,city,regionName,country");
        xhr.send();
    }

    function fetch_forecast(lat, lon, location_name) {
        const unit_c = root.settings.unit === "celsius";
        const days_count = Math.max(1, Math.min(16, root.settings.days || 7));
        const params = {
            latitude: lat,
            longitude: lon,
            current: "temperature_2m,apparent_temperature,is_day,precipitation,weather_code",
            hourly: "temperature_2m,precipitation_probability,precipitation,weather_code,is_day",
            daily: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset",
            temperature_unit: unit_c ? "celsius" : "fahrenheit",
            precipitation_unit: unit_c ? "mm" : "inch",
            timezone: "auto",
            forecast_days: days_count
        };
        const query = Object.keys(params).map(k => encodeURIComponent(k) + "=" + encodeURIComponent(params[k])).join("&");

        const xhr = new XMLHttpRequest();
        xhr.timeout = root.request_timeout_ms;
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    root.handle_forecast(data, location_name);
                } catch (e) {
                    root.fail("forecast parse error: " + e);
                }
            } else {
                root.fail("forecast request failed: " + xhr.status);
            }
        };
        xhr.onerror = () => root.fail("forecast request network error");
        xhr.ontimeout = () => root.fail("forecast request timed out");
        xhr.open("GET", "https://api.open-meteo.com/v1/forecast?" + query);
        xhr.send();
    }

    function handle_forecast(blob, location_name) {
        try {
            const parsed = root.parse_blob(blob, location_name);
            root.apply_data(parsed);
            root.last_success_ms = Date.now();
            root.loading = false;
            root.error = "";
            root.stale = false;
            root.warned_once = false;
            cache_file.setText(JSON.stringify(parsed));
        } catch (e) {
            root.fail("parse error: " + e);
        }
    }

    function fail(msg) {
        root.loading = false;
        root.stale = root.has_data;
        root.error = msg;
        if (!root.warned_once) {
            console.warn("Weather: " + msg);
            root.warned_once = true;
        }
    }

    function apply_data(parsed) {
        root.current = parsed.current;
        root.hours = parsed.hours;
        root.days = parsed.days;
        root.location_name = parsed.location_name;
        root.updated = parsed.updated;
        root.sunrise = parsed.sunrise;
        root.sunset = parsed.sunset;
        root.moon = parsed.moon;
        root.utc_offset = parsed.utc_offset || 0;
        root.has_data = true;
    }

    // Wall-clock time at the forecast location; read it with the getUTC* methods.
    function location_now() {
        return new Date(Date.now() + root.utc_offset * 1000);
    }

    function location_date_str() {
        return root.location_now().toISOString().substr(0, 10);
    }

    function parse_num(val, def) {
        const n = parseFloat(val);
        return isNaN(n) ? def : n;
    }

    function fmt_time(iso) {
        if (!iso) return "";
        const idx = iso.indexOf("T");
        return idx === -1 ? "" : iso.substr(idx + 1, 5);
    }

    function parse_blob(blob, location_name) {
        const cur = blob.current;
        const hourly = blob.hourly;
        const daily = blob.daily;
        const now_local = new Date(cur.time);

        const current = {
            temp: root.parse_num(cur.temperature_2m, 0),
            feels: root.parse_num(cur.apparent_temperature, 0),
            code: Math.round(root.parse_num(cur.weather_code, 0)),
            is_day: cur.is_day ? 1 : 0,
            precip: root.parse_num(cur.precipitation, 0),
            cond: root.description(cur.weather_code)
        };

        // Every remaining hour across every fetched day (the Hourly popup tab scrolls the whole range).
        const all_hours = [];
        for (let i = 0; i < hourly.time.length; i++) {
            const dt = new Date(hourly.time[i]);
            all_hours.push({
                dt: dt.toISOString(),
                date: Qt.formatDate(dt, "yyyy-MM-dd"),
                hour: dt.getHours(),
                temp: root.parse_num(hourly.temperature_2m[i], 0),
                pop: Math.round(root.parse_num(hourly.precipitation_probability[i], 0)),
                precip: root.parse_num(hourly.precipitation[i], 0),
                code: Math.round(root.parse_num(hourly.weather_code[i], 0)),
                is_day: hourly.is_day[i] ? 1 : 0,
                cond: root.description(hourly.weather_code[i])
            });
        }
        let next_hours = all_hours.filter(h => new Date(h.dt) >= now_local);
        if (next_hours.length === 0 && all_hours.length > 0) next_hours = all_hours;

        const day_limit = Math.max(1, Math.min(16, root.settings.days || 7));
        const days = [];
        for (let i = 0; i < Math.min(day_limit, daily.time.length); i++) {
            const date_str = daily.time[i];
            const d = new Date(date_str + "T00:00:00");
            days.push({
                date: date_str,
                weekday: i === 0 ? "Today" : Qt.formatDate(d, "ddd"),
                min: root.parse_num(daily.temperature_2m_min[i], 0),
                max: root.parse_num(daily.temperature_2m_max[i], 0),
                code: Math.round(root.parse_num(daily.weather_code[i], 0)),
                cond: root.description(daily.weather_code[i]),
                pop: Math.round(root.parse_num(daily.precipitation_probability_max[i], 0)),
                precip: root.parse_num(daily.precipitation_sum[i], 0),
                sunrise: root.fmt_time(daily.sunrise[i]),
                sunset: root.fmt_time(daily.sunset[i])
            });
        }

        const today = days.length > 0 ? days[0] : null;
        const phase = root.moon_phase(now_local);

        return {
            current: current,
            hours: next_hours,
            days: days,
            location_name: location_name || blob.timezone || "",
            updated: Date.now(),
            sunrise: today ? today.sunrise : "",
            sunset: today ? today.sunset : "",
            moon: { phase: phase, name: root.moon_name(phase) },
            utc_offset: blob.utc_offset_seconds || 0,
            settings_key: JSON.stringify(root.settings)
        };
    }

    // --- Moon phase (ported from MoonPhase.calculate_phase / phase_name) ---

    readonly property double known_new_moon_ms: Date.UTC(2000, 0, 6, 18, 14, 0)
    readonly property double lunar_cycle_days: 29.530588861

    function moon_phase(date) {
        const days_since = (date.getTime() - root.known_new_moon_ms) / 86400000.0;
        let phase = (days_since % root.lunar_cycle_days) / root.lunar_cycle_days;
        phase = phase % 1.0;
        return phase < 0 ? phase + 1.0 : phase;
    }

    function moon_name(phase) {
        if (phase < 0.0625 || phase >= 0.9375) return "New Moon";
        if (phase < 0.1875) return "Waxing Crescent";
        if (phase < 0.3125) return "First Quarter";
        if (phase < 0.4375) return "Waxing Gibbous";
        if (phase < 0.5625) return "Full Moon";
        if (phase < 0.6875) return "Waning Gibbous";
        if (phase < 0.8125) return "Last Quarter";
        return "Waning Crescent";
    }

    readonly property var moon_icon_slugs: ({
        new: "moon-new",
        waxing_crescent: "moon-waxing-crescent",
        first_quarter: "moon-first-quarter",
        waxing_gibbous: "moon-waxing-gibbous",
        full: "moon-full",
        waning_gibbous: "moon-waning-gibbous",
        last_quarter: "moon-last-quarter",
        waning_crescent: "moon-waning-crescent"
    })

    function moon_phase_key(phase) {
        if (phase < 0.0625 || phase >= 0.9375) return "new";
        if (phase < 0.1875) return "waxing_crescent";
        if (phase < 0.3125) return "first_quarter";
        if (phase < 0.4375) return "waxing_gibbous";
        if (phase < 0.5625) return "full";
        if (phase < 0.6875) return "waning_gibbous";
        if (phase < 0.8125) return "last_quarter";
        return "waning_crescent";
    }

    function asset_url(slug) {
        return Qt.resolvedUrl("../assets/weather/" + slug + ".svg");
    }

    function moon_icon_source(phase) {
        return root.asset_url(root.moon_icon_slugs[root.moon_phase_key(phase)]);
    }

    readonly property string sun_rise_icon: root.asset_url("sunrise")
    readonly property string sun_set_icon: root.asset_url("sunset")
    readonly property string raindrop_icon: root.asset_url("raindrop")

    // --- WMO condition codes, mapped to vendored Meteocons fill-style SVGs ---
    // (assets/weather/, from @meteocons/svg-static, MIT license)

    readonly property var weather_icon_map: ({
        0: { day: "clear-day", night: "clear-night", desc: "Clear sky" },
        1: { day: "mostly-clear-day", night: "mostly-clear-night", desc: "Mainly clear" },
        2: { day: "partly-cloudy-day", night: "partly-cloudy-night", desc: "Partly cloudy" },
        3: { day: "overcast-day", night: "overcast-night", desc: "Overcast" },
        45: { day: "fog-day", night: "fog-night", desc: "Fog" },
        48: { day: "fog-day", night: "fog-night", desc: "Depositing rime fog" },
        51: { day: "drizzle", night: "drizzle", desc: "Light drizzle" },
        53: { day: "drizzle", night: "drizzle", desc: "Moderate drizzle" },
        55: { day: "overcast-drizzle", night: "overcast-drizzle", desc: "Dense drizzle" },
        56: { day: "sleet", night: "sleet", desc: "Light freezing drizzle" },
        57: { day: "sleet", night: "sleet", desc: "Dense freezing drizzle" },
        61: { day: "rain", night: "rain", desc: "Slight rain" },
        63: { day: "overcast-rain", night: "overcast-rain", desc: "Moderate rain" },
        65: { day: "extreme-rain", night: "extreme-rain", desc: "Heavy rain" },
        66: { day: "sleet", night: "sleet", desc: "Light freezing rain" },
        67: { day: "extreme-sleet", night: "extreme-sleet", desc: "Heavy freezing rain" },
        71: { day: "snow", night: "snow", desc: "Slight snow fall" },
        73: { day: "overcast-snow", night: "overcast-snow", desc: "Moderate snow fall" },
        75: { day: "extreme-snow", night: "extreme-snow", desc: "Heavy snow fall" },
        77: { day: "snow", night: "snow", desc: "Snow grains" },
        80: { day: "rain", night: "rain", desc: "Slight rain showers" },
        81: { day: "overcast-rain", night: "overcast-rain", desc: "Moderate rain showers" },
        82: { day: "extreme-rain", night: "extreme-rain", desc: "Violent rain showers" },
        85: { day: "snow", night: "snow", desc: "Slight snow showers" },
        86: { day: "extreme-snow", night: "extreme-snow", desc: "Heavy snow showers" },
        95: { day: "thunderstorms", night: "thunderstorms", desc: "Thunderstorm" },
        96: { day: "thunderstorms-hail", night: "thunderstorms-hail", desc: "Thunderstorm with slight hail" },
        99: { day: "extreme-thunderstorms-hail", night: "extreme-thunderstorms-hail", desc: "Thunderstorm with heavy hail" }
    })

    readonly property var weather_color_keys: ({
        0: "clear", 1: "clear", 2: "partly_cloudy", 3: "overcast",
        45: "fog", 48: "fog",
        51: "drizzle", 53: "drizzle", 55: "drizzle", 56: "freezing_rain", 57: "freezing_rain",
        61: "rain", 63: "rain", 65: "heavy_rain", 66: "freezing_rain", 67: "freezing_rain",
        71: "snow", 73: "snow", 75: "heavy_snow", 77: "heavy_snow",
        80: "rain", 81: "rain", 82: "heavy_rain", 85: "snow", 86: "heavy_snow",
        95: "thunderstorm", 96: "thunderstorm", 99: "thunderstorm"
    })

    function icon_source(code, is_day) {
        const entry = root.weather_icon_map[Math.round(code)];
        if (!entry) return root.asset_url("not-available");
        return root.asset_url(is_day ? entry.day : (entry.night || entry.day));
    }

    function description(code) {
        const entry = root.weather_icon_map[Math.round(code)];
        return entry ? entry.desc : "Unknown";
    }

    function condition_color(code, is_day) {
        const key = root.weather_color_keys[Math.round(code)] || "clear";
        switch (key) {
        case "clear": return is_day ? Theme.yellow : Theme.magenta;
        case "partly_cloudy": return is_day ? Theme.bright_yellow : Theme.bright_magenta;
        case "overcast": return Theme.fg_dim;
        case "fog": return Theme.fg_dim;
        case "drizzle": return Theme.cyan;
        case "rain": return Theme.blue;
        case "heavy_rain": return Theme.bright_blue;
        case "freezing_rain": return Theme.bright_cyan;
        case "snow": return Theme.cyan;
        case "heavy_snow": return Theme.bright_cyan;
        case "thunderstorm": return Theme.yellow;
        default: return Theme.theme_primary;
        }
    }

    // --- Temperature and precipitation bands (ported from Temperature / Precipitation) ---

    function temp_color(temp) {
        const unit_c = root.settings.unit === "celsius";
        const very_cold = unit_c ? 5 : 41;
        const cold = unit_c ? 18 : 65;
        const chilly = unit_c ? 19 : 66;
        const neutral = unit_c ? 24 : 76;
        const warm = unit_c ? 29 : 85;
        if (temp < very_cold) return Theme.bright_cyan;
        if (temp < cold) return Theme.cyan;
        if (temp < chilly) return Theme.bright_green;
        if (temp < neutral) return Theme.green;
        if (temp < warm) return Theme.yellow;
        return Theme.red;
    }

    function pop_color(pop) {
        const p = Math.max(0, Math.min(100, pop));
        if (p < 30) return Theme.fg_muted;
        if (p < 60) return Theme.magenta;
        if (p < 80) return Theme.bright_magenta;
        return Theme.red;
    }

    function unit_symbol() {
        return root.settings.unit === "celsius" ? "C" : "F";
    }

    function format_hour(date) {
        const d = date instanceof Date ? date : new Date(date);
        if (root.settings.time_format === "12h") {
            let h = d.getHours() % 12;
            if (h === 0) h = 12;
            const ampm = d.getHours() < 12 ? "am" : "pm";
            return (h < 10 ? "0" + h : "" + h) + " " + ampm;
        }
        const hh = d.getHours();
        return hh < 10 ? "0" + hh : "" + hh;
    }
}
