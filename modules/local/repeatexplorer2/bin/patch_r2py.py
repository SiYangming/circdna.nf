#!/usr/bin/env python3
"""幂等 Rserve 重试 patch：r2py.py 固定 sleep(1) 连接一次 -> 30 次重试。
用法: python patch_r2py.py <r2py.py 路径>
已含重试逻辑则跳过（幂等）。
"""
import sys

OLD = """    time.sleep(1)
    try:
        conn = pyRserve.connect(port=config.RSERVE_PORT)
        print("connection OK")
        conn.close()
        atexit.register(shutdown, config.RSERVE_PORT)
        return config.RSERVE_PORT
    except:
        print("Connection with Rserve was not established!")
        raise"""

NEW = """    conn = None
    for _try in range(30):
        time.sleep(1)
        try:
            conn = pyRserve.connect(port=config.RSERVE_PORT)
            print("connection OK")
            conn.close()
            atexit.register(shutdown, config.RSERVE_PORT)
            return config.RSERVE_PORT
        except Exception as _e:
            print("Rserve not ready (try %d): %s" % (_try, _e))
    raise ConnectionError("Rserve did not start in 30s")"""


def main():
    if len(sys.argv) < 2:
        print("usage: patch_r2py.py <r2py.py path>", file=sys.stderr)
        sys.exit(1)
    p = sys.argv[1]
    s = open(p).read()
    if "Rserve did not start in 30s" in s:
        print("already patched, skip: %s" % p)
        return 0
    if OLD not in s:
        print("pattern not found in %s, skip" % p, file=sys.stderr)
        return 1
    open(p, "w").write(s.replace(OLD, NEW))
    print("patched OK: %s" % p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
