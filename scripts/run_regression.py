#!/usr/bin/env python3
"""Small, reproducible regression launcher and result summarizer."""
from __future__ import annotations
import argparse, csv, pathlib, subprocess, time

TESTS = [
    ("bridge_smoke_test", 1),
    ("bridge_base_test", 29),
    ("bridge_base_test", 47),
    ("bridge_base_test", 83),
    ("bridge_base_test", 101),
    ("bridge_error_test", 7),
]

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", choices=("questa", "vcs"), default="questa")
    args = parser.parse_args()
    pathlib.Path("logs").mkdir(exist_ok=True)
    rows=[]
    for test,seed in TESTS:
        start=time.monotonic()
        target="uvm" if args.backend=="questa" else "vcs"
        cmd=["make",target,f"TEST={test}",f"SEED={seed}"]
        result=subprocess.run(cmd,text=True,capture_output=True)
        elapsed=round(time.monotonic()-start,2)
        status="PASS" if result.returncode==0 and "AXI_APB_UVM_PASS" in result.stdout else "FAIL"
        log=pathlib.Path("logs")/f"runner_{test}_{seed}.log"
        log.write_text(result.stdout+"\n"+result.stderr,encoding="utf-8")
        rows.append({"test":test,"seed":seed,"status":status,"seconds":elapsed,"log":str(log)})
        print(f"{status:4} {test:24} seed={seed:5} {elapsed:7.2f}s")
    with open("logs/regression_summary.csv","w",newline="",encoding="utf-8") as handle:
        writer=csv.DictWriter(handle,fieldnames=rows[0].keys()); writer.writeheader(); writer.writerows(rows)
    failed=sum(r["status"]=="FAIL" for r in rows)
    print(f"REGRESSION {'PASS' if failed==0 else 'FAIL'} total={len(rows)} failed={failed}")
    return 1 if failed else 0

if __name__=="__main__": raise SystemExit(main())
