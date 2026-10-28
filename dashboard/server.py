import argparse
import datetime
import decimal
import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import psycopg2

HERE = Path(__file__).resolve().parent
QUERIES = HERE.parent / "model" / "queries"
MAX_ROWS = 1000
MAX_BODY = 100_000

DSN = dict(
    host=os.environ.get("PGHOST", "localhost"),
    port=int(os.environ.get("PGPORT", "5432")),
    dbname=os.environ.get("PGDATABASE", "marketplace"),
    user=os.environ.get("PGUSER", "viewer"),
    password=os.environ.get("PGPASSWORD", "viewer"),
    connect_timeout=5,
)

DASH_QUERIES = {
    "q1": "task_01.sql", "q2": "task_02.sql", "q3": "task_03.sql", "q4": "task_04.sql",
    "q5": "task_05.sql", "inflight": "dash_in_progress.sql",
}
EXAMPLES = [
    ("Вопрос 1. Выручка и заказы по месяцам", "task_01.sql"),
    ("Вопрос 2. Топ-10 продавцов", "task_02.sql"),
    ("Вопрос 3. Средний чек", "task_03.sql"),
    ("Вопрос 4. Покупатели и повторные покупки", "task_04.sql"),
    ("Вопрос 5. Выручка по категориям", "task_05.sql"),
]

def encoder(exact):
    """exact=True: numeric уходит строкой (точные деньги в консоли); иначе числом (для графиков)."""
    def default(o):
        if isinstance(o, decimal.Decimal):
            return str(o) if exact else float(o)
        if isinstance(o, (datetime.date, datetime.datetime, datetime.time)):
            return o.isoformat(sep=" ") if isinstance(o, datetime.datetime) else o.isoformat()
        return str(o)
    return default

def run_query(sql, max_rows=MAX_ROWS):
    """Выполняет один запрос под ролью viewer и возвращает (колонки, строки, обрезано, мс)."""
    conn = psycopg2.connect(**DSN)
    try:
        conn.set_session(readonly=True)
        with conn.cursor() as cur:
            t0 = time.perf_counter()
            cur.execute(sql)
            if cur.description is None:
                return [], [], False, round((time.perf_counter() - t0) * 1000)
            columns = [d.name for d in cur.description]
            rows = cur.fetchmany(max_rows + 1)
            ms = round((time.perf_counter() - t0) * 1000)
        conn.rollback()
        return columns, [list(r) for r in rows[:max_rows]], len(rows) > max_rows, ms
    finally:
        conn.close()

def read_sql(name):
    return (QUERIES / name).read_text(encoding="utf-8")

class Handler(BaseHTTPRequestHandler):
    server_version = "CapibaraDash/1.0"

    def log_message(self, fmt, *args):
        pass

    def send_json(self, payload, status=200, exact=False):
        body = json.dumps(payload, ensure_ascii=False, default=encoder(exact)).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def host_ok(self):
        """Защита от чужих сайтов, стучащихся на localhost: Host и Origin должны быть своими."""
        port = self.server.server_address[1]
        host = self.headers.get("Host", "")
        if host not in (f"127.0.0.1:{port}", f"localhost:{port}"):
            return False
        origin = self.headers.get("Origin")
        return origin is None or origin == f"http://{host}"

    def do_GET(self):
        if not self.host_ok():
            return self.send_json({"error": "forbidden"}, 403)
        path = self.path.split("?")[0]
        try:
            if path in ("/", "/index.html"):
                body = (HERE / "index.html").read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            elif path == "/api/dashboard":
                self.send_json(self.dashboard())
            elif path == "/api/schema":
                self.send_json(self.schema())
            elif path == "/api/examples":
                self.send_json([{"title": t, "sql": read_sql(f)} for t, f in EXAMPLES])
            else:
                self.send_json({"error": "not found"}, 404)
        except psycopg2.Error as e:
            self.send_json({"error": f"База недоступна или модель не собрана: {e}".strip()}, 503)

    def do_POST(self):
        if not self.host_ok():
            return self.send_json({"error": "forbidden"}, 403)
        if self.path.split("?")[0] != "/api/sql":
            return self.send_json({"error": "not found"}, 404)
        length = int(self.headers.get("Content-Length") or 0)
        if length > MAX_BODY:
            return self.send_json({"error": "Запрос слишком большой"}, 413)
        try:
            sql = (json.loads(self.rfile.read(length) or b"{}").get("sql") or "").strip()
        except ValueError:
            return self.send_json({"error": "Некорректный JSON"}, 400)
        if not sql:
            return self.send_json({"error": "Пустой запрос"}, 400)
        try:
            columns, rows, truncated, ms = run_query(sql)
        except psycopg2.Error as e:
            msg = (e.pgerror or str(e)).strip()
            return self.send_json({"error": msg}, 400)
        self.send_json({"columns": columns, "rows": rows, "truncated": truncated,
                        "max_rows": MAX_ROWS, "ms": ms}, exact=True)

    def dashboard(self):
        out = {}
        for key, fname in DASH_QUERIES.items():
            columns, rows, _, _ = run_query(read_sql(fname), max_rows=10_000)
            out[key] = [dict(zip(columns, r)) for r in rows]
        return out

    def schema(self):
        _, rows, _, _ = run_query(
            "SELECT table_schema, table_name, column_name, data_type FROM information_schema.columns "
            "WHERE table_schema IN ('core','mart') ORDER BY table_schema, table_name, ordinal_position")
        result = {}
        for schema, table, column, dtype in rows:
            result.setdefault(schema, {}).setdefault(table, []).append([column, dtype])
        return result

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--port", type=int, default=8000)
    args = ap.parse_args()
    srv = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"Дашборд: http://127.0.0.1:{args.port}  (Ctrl+C, чтобы остановить)", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
