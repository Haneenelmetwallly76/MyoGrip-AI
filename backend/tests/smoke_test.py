import argparse
import datetime
import json
import random
import sqlite3
import sys
import time
import urllib.error
import urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("--base", default="http://localhost:5080")
ap.add_argument("--ai-url", default="http://localhost:8000")
ap.add_argument("--ai", action="store_true")
ap.add_argument("--db")
ap.add_argument("--clinician-password")
args = ap.parse_args()

passed = failed = 0


def call(method, path, body=None, token=None, base=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request((base or args.base) + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, raw


def check(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  PASS  {name}")
    else:
        failed += 1
        print(f"  FAIL  {name}  {detail}")


stamp = f"{int(time.time())}{random.randint(0, 999)}"
email = f"patient{stamp}@example.com"
password = "S3cret-pass!"

print("AUTH")
s, b = call("POST", "/api/auth/register",
            {"fullName": "Test Patient", "age": 34, "email": email, "password": password, "clinicCode": "QA-1024"})
check("register -> 201", s == 201 and b.get("email") == email, (s, b))
s, b = call("POST", "/api/auth/register",
            {"fullName": "Test Patient", "age": 34, "email": email, "password": password, "clinicCode": "QA-1024"})
check("register duplicate email -> 409", s == 409, (s, b))
s, b = call("POST", "/api/auth/register",
            {"fullName": "X", "age": 30, "email": f"x{stamp}@example.com", "password": password, "clinicCode": "NOPE"})
check("register bad clinic code -> 400 INVALID_CLINIC_CODE", s == 400 and b.get("code") == "INVALID_CLINIC_CODE", (s, b))
s, b = call("POST", "/api/auth/register",
            {"fullName": "X", "age": 30, "email": "not-an-email", "password": "short", "clinicCode": "QA-1024"})
check("register invalid fields -> 400 with errors.email and errors.password",
      s == 400 and b.get("code") == "VALIDATION_ERROR" and "email" in b.get("errors", {}) and "password" in b.get("errors", {}), (s, b))
s, b = call("POST", "/api/auth/login", {"email": email, "password": "wrong-password"})
check("login wrong password -> 401", s == 401, (s, b))
s, b = call("POST", "/api/auth/login", {"email": email, "password": password})
check("login -> 200 + token", s == 200 and b.get("accessToken") and b.get("expiresIn") == 3600, (s, b))
token = b.get("accessToken") if isinstance(b, dict) else None
uid1 = b["user"]["userId"] if isinstance(b, dict) and "user" in b else None

print("PROFILE")
s, b = call("GET", "/api/user/profile")
check("profile without token -> 401", s == 401, (s, b))
s, b = call("GET", "/api/user/profile", token=token)
check("profile -> 200 with clinician", s == 200 and b.get("clinicCode") == "QA-1024" and b["clinician"]["name"] == "Dr. Example", (s, b))
s, b = call("PUT", "/api/user/profile", {"fullName": "Test Patient", "age": 35, "email": email}, token=token)
check("update profile -> 200, age 35", s == 200 and b.get("age") == 35, (s, b))

print("SETTINGS")
s, b = call("GET", "/api/prosthetic/settings", token=token)
check("settings before any PUT -> 404", s == 404, (s, b))
s, b = call("PUT", "/api/prosthetic/settings", {"sensitivity": 75, "activeGrips": [0, 1, 3, 5], "tensEnabled": True}, token=token)
check("update settings -> 200, deliveryStatus pending", s == 200 and b.get("deliveryStatus") == "pending", (s, b))
s, b = call("GET", "/api/prosthetic/settings", token=token)
check("get settings returns what was saved", s == 200 and b.get("activeGrips") == [0, 1, 3, 5] and b.get("sensitivity") == 75 and b.get("tensEnabled") is True, (s, b))
s, b = call("PUT", "/api/prosthetic/settings", {"sensitivity": 150, "activeGrips": [0, 1], "tensEnabled": True}, token=token)
check("sensitivity 150 -> 400", s == 400, (s, b))
s, b = call("PUT", "/api/prosthetic/settings", {"sensitivity": 50, "activeGrips": [0, 0], "tensEnabled": True}, token=token)
check("duplicate grips -> 400", s == 400, (s, b))
s, b = call("PUT", "/api/prosthetic/settings", {"sensitivity": 50, "activeGrips": [], "tensEnabled": True}, token=token)
check("empty grips -> 400", s == 400, (s, b))

print("SYNC LOGS")
batch = f"batch-{stamp}"
good = {"batchId": batch, "entries": [
    {"timestamp": "2026-10-17T09:12:00Z", "type": "usage", "gesture": 3, "gripStrength": 0.62, "durationSeconds": 14},
    {"timestamp": "2026-10-17T09:40:10Z", "type": "error", "message": "WIFI_TIMEOUT"}]}
s, b = call("POST", "/api/prosthetic/sync-logs", good, token=token)
check("sync valid batch -> 200 accepted 2", s == 200 and b.get("accepted") == 2 and b.get("rejected") == 0, (s, b))
s, b = call("POST", "/api/prosthetic/sync-logs", good, token=token)
check("resend same batchId -> 200, still accepted 2", s == 200 and b.get("accepted") == 2, (s, b))
if args.db:
    con = sqlite3.connect(args.db)
    n = con.execute("SELECT COUNT(*) FROM LogEntries le JOIN SyncBatches sb ON le.SyncBatchId = sb.Id WHERE sb.BatchId = ?", (batch,)).fetchone()[0]
    con.close()
    check("database holds exactly 2 rows for that batch (no duplicates)", n == 2, f"found {n}")
mixed = {"batchId": f"mixed-{stamp}", "entries": [
    {"timestamp": "2026-10-17T10:00:00Z", "type": "usage", "gesture": 2, "gripStrength": 0.4, "durationSeconds": 5},
    {"timestamp": "2026-10-17T10:01:00Z", "type": "usage", "gesture": 99, "gripStrength": 0.4, "durationSeconds": 5}]}
s, b = call("POST", "/api/prosthetic/sync-logs", mixed, token=token)
check("mixed batch -> 200 accepted 1 rejected 1", s == 200 and b.get("accepted") == 1 and b.get("rejected") == 1 and b["rejectedItems"][0]["index"] == 1, (s, b))
allbad = {"batchId": f"bad-{stamp}", "entries": [{"timestamp": "2026-10-17T10:00:00Z", "type": "weird"}]}
s, b = call("POST", "/api/prosthetic/sync-logs", allbad, token=token)
check("all-invalid batch -> 400 with rejectedItems", s == 400 and len(b.get("rejectedItems", [])) == 1, (s, b))
big = {"batchId": f"big-{stamp}", "entries": [{"timestamp": "2026-10-17T10:00:00Z", "type": "error", "message": "x"}] * 501}
s, b = call("POST", "/api/prosthetic/sync-logs", big, token=token)
check("501 entries -> 413", s == 413, (s, b))

print("USAGE + REPORT")
s, b = call("GET", "/api/prosthetic/usage?from=2026-10-17&to=2026-10-17", token=token)
day = b["days"][0] if s == 200 and b.get("days") else {}
check("usage for 2026-10-17 -> 19 s = 0.005 h, 1 error", s == 200 and abs(day.get("usageHours", 0) - 19 / 3600) < 0.0006 and day.get("errorCount") == 1, (s, b))
check("usage grip strength is duration-weighted (0.562)", abs((day.get("avgGripStrength") or 0) - 0.5621) < 0.001, day)
s, b = call("GET", "/api/prosthetic/usage?from=2026-10-01&to=2026-10-30", token=token)
check("usage range is zero-filled (30 days)", s == 200 and len(b.get("days", [])) == 30 and b.get("lastSyncedAt"), (s, str(b)[:200]))
s, b = call("GET", "/api/prosthetic/usage?from=2026-10-20&to=2026-10-01", token=token)
check("usage with from after to -> 400", s == 400, (s, b))
s, b = call("GET", "/api/prosthetic/usage")
check("usage without token -> 401", s == 401, (s, b))
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
recent = {"batchId": f"recent-{stamp}", "entries": [{"timestamp": now, "type": "usage", "gesture": 1, "gripStrength": 0.5, "durationSeconds": 60}]}
s, b = call("POST", "/api/prosthetic/sync-logs", recent, token=token)
check("sync a usage entry from right now", s == 200 and b.get("accepted") == 1, (s, b))
s, b = call("POST", "/api/reports/send", {}, token=token)
check("send report -> 201 with clinician name", s == 201 and b.get("clinicianName") == "Dr. Example" and b.get("reportId"), (s, b))
report_id = b.get("reportId") if isinstance(b, dict) else None

print("ISOLATION (a second patient must not see the first one's data)")
email2 = f"other{stamp}@example.com"
call("POST", "/api/auth/register", {"fullName": "Other Patient", "age": 40, "email": email2, "password": password, "clinicCode": "QA-2048"})
s, b = call("POST", "/api/auth/login", {"email": email2, "password": password})
token2 = b.get("accessToken") if isinstance(b, dict) else None
uid2 = b["user"]["userId"] if isinstance(b, dict) and "user" in b else None
s, b = call("GET", "/api/prosthetic/settings", token=token2)
check("second patient has no settings (404, not patient 1's)", s == 404, (s, b))
s, b = call("GET", "/api/user/profile", token=token2)
check("second patient sees own profile", s == 200 and b.get("email") == email2, (s, b))
s, b = call("POST", "/api/reports/send", {}, token=token2)
check("report with no data -> 400 NO_USAGE_DATA", s == 400 and b.get("code") == "NO_USAGE_DATA", (s, b))

if args.clinician_password:
    print("CLINICIAN DASHBOARD")
    s, b = call("POST", "/api/auth/login", {"email": "clinician-qa-1024@myogrip.test", "password": args.clinician_password})
    ctoken = b.get("accessToken") if isinstance(b, dict) else None
    check("clinician login -> role Clinician", s == 200 and b["user"]["role"] == "Clinician", (s, b))
    s, b = call("GET", "/api/clinic/patients", token=ctoken)
    ids = [p["userId"] for p in b.get("items", [])] if s == 200 else []
    check("patient list has own clinic's patient, not the other clinic's", uid1 in ids and uid2 not in ids, (s, ids))
    s, b = call("GET", f"/api/clinic/patients/{uid1}", token=ctoken)
    check("patient detail -> 200 with settings", s == 200 and b["settings"]["sensitivity"] == 75, (s, b))
    s, b = call("GET", f"/api/clinic/patients/{uid2}", token=ctoken)
    check("patient from another clinic -> 404", s == 404, (s, b))
    s, b = call("GET", f"/api/clinic/patients/{uid1}/usage?from=2026-10-17&to=2026-10-17", token=ctoken)
    check("clinician sees patient usage", s == 200 and b["days"][0]["errorCount"] == 1, (s, b))
    s, b = call("GET", f"/api/clinic/patients/{uid1}/errors", token=ctoken)
    check("clinician sees error log", s == 200 and any(i["message"] == "WIFI_TIMEOUT" for i in b.get("items", [])), (s, b))
    s, b = call("GET", "/api/clinic/reports", token=ctoken)
    mine = [r for r in b.get("items", []) if r["reportId"] == report_id] if s == 200 else []
    check("report appears in clinician inbox, unread", len(mine) == 1 and mine[0]["read"] is False, (s, b))
    s, b = call("POST", f"/api/clinic/reports/{report_id}/read", {}, token=ctoken)
    check("mark report read -> 200", s == 200 and b.get("read") is True, (s, b))
    s, b = call("GET", "/api/clinic/patients", token=token)
    check("patient token on clinic endpoint -> 403", s == 403, (s, b))
    s, b = call("GET", "/api/user/profile", token=ctoken)
    check("clinician token on patient endpoint -> 403", s == 403, (s, b))

if args.ai:
    print("AI")
    window = [[random.gauss(0, 1) for _ in range(8)] for _ in range(200)]
    s, b = call("POST", "/predict", {"window": window}, base=args.ai_url)
    check("AI service rejects missing service key -> 401", s == 401, (s, b))
    s, b = call("POST", "/api/ai/predict", {"window": window}, token=token)
    ok = s == 200 and isinstance(b, dict) and 0 <= b.get("gesture", -1) <= 5 and "uncertainty" in b
    check("api -> ai predict -> 200 with gesture 0-5", ok, (s, b))
    if ok:
        print(f"        (random-noise input, so the class itself means nothing: {b})")
    s, b = call("POST", "/api/ai/predict", {"window": window[:10]}, token=token)
    check("wrong window shape -> 400", s == 400, (s, b))
    s, b = call("POST", "/api/ai/predict", {"window": window})
    check("predict without token -> 401", s == 401, (s, b))

print("RATE LIMIT (last: it locks you out for a minute)")
got_429 = False
for _ in range(20):
    s, _b = call("POST", "/api/auth/login", {"email": email, "password": "wrong-password"})
    if s == 429:
        got_429 = True
        break
check("repeated logins eventually -> 429", got_429)

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
