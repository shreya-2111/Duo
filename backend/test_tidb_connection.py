"""
TiDB Cloud Starter / Serverless Connection Diagnostic Script
Usage:
  python test_tidb_connection.py
Reads connection details from DATABASE_URL or DB_* environment variables.
"""
import os
import ssl
import sys
import urllib.parse
import pymysql

def test_connection():
    print("=" * 60)
    print("   DUO BACKEND - TiDB CLOUD CONNECTION DIAGNOSTIC")
    print("=" * 60)

    db_url = os.getenv("DATABASE_URL")
    if db_url:
        print(f"[1/4] Parsing DATABASE_URL...")
        parsed = urllib.parse.urlparse(db_url)
        host = parsed.hostname
        port = parsed.port or 4000
        user = urllib.parse.unquote(parsed.username) if parsed.username else ""
        password = urllib.parse.unquote(parsed.password) if parsed.password else ""
        db_name = parsed.path.lstrip('/')
    else:
        print(f"[1/4] Reading individual DB_* environment variables...")
        host = os.getenv("DB_HOST", "127.0.0.1")
        port = int(os.getenv("DB_PORT", "4000"))
        user = os.getenv("DB_USER", "root")
        password = os.getenv("DB_PASSWORD", "")
        db_name = os.getenv("DB_NAME", "duo_db")

    masked_pw = ("*" * len(password)) if password else "(empty)"
    print(f"      Host: {host}")
    print(f"      Port: {port}")
    print(f"      User: {user}")
    print(f"      Database: {db_name}")
    print(f"      Password: {masked_pw}")

    is_tidb = ("tidbcloud.com" in (host or "").lower()) or (port == 4000)
    print(f"[2/4] TiDB Cloud Detected: {is_tidb}")

    ssl_context = None
    if is_tidb:
        print("      Configuring SSL context for TiDB Cloud...")
        ssl_context = ssl.create_default_context()

    print("[3/4] Establishing database connection...")
    try:
        conn = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=db_name,
            ssl=ssl_context,
            connect_timeout=15,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        print("      SUCCESS: Connected to database successfully!")
    except Exception as e:
        print(f"\n❌ CONNECTION FAILED: {e}")
        print("\nTroubleshooting tips for TiDB Cloud Starter:")
        print("1. Ensure cluster is ACTIVE in tidbcloud.com console.")
        print("2. Ensure username includes the prefix (e.g. 'xxxxx.root').")
        print("3. Ensure IP access list in TiDB Cloud allows '0.0.0.0/0' (All IPs).")
        print("4. Verify port is 4000.")
        return False

    try:
        print("[4/4] Verifying server version and schema...")
        with conn.cursor() as cursor:
            cursor.execute("SELECT VERSION() AS ver, DATABASE() AS current_db, NOW() AS db_time;")
            info = cursor.fetchone()
            print(f"      Server Version: {info['ver']}")
            print(f"      Connected DB:   {info['current_db']}")
            print(f"      Database Time:  {info['db_time']}")

            cursor.execute("SHOW TABLES;")
            tables = cursor.fetchall()
            print(f"      Total Tables:   {len(tables)}")
            table_names = [list(t.values())[0] for t in tables]
            print(f"      Tables: {', '.join(table_names[:10])}{' ...' if len(table_names) > 10 else ''}")

        conn.close()
        print("\nAll database checks passed cleanly! TiDB Cloud is ready for Duo.")
        return True
    except Exception as e:
        print(f"\n❌ QUERY FAILED: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)

