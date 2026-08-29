#!/usr/bin/env python3
"""Static check: require(script.Parent...) chains resolve to files on disk."""
from pathlib import Path
import re

ROOT = Path("/Users/GreysonAMcCann/VOIDZ_Platform/src")
fails = []
checked = 0

def file_for(module_path):
    if module_path.with_suffix(".lua").exists():
        return module_path.with_suffix(".lua")
    for suffix in (".server.lua", ".client.lua"):
        p = Path(str(module_path) + suffix)
        if p.exists():
            return p
    if module_path.is_dir() and (module_path / "init.lua").exists():
        return module_path / "init.lua"
    return None

req_re = re.compile(r'require\((.*?)\)')

for lua in ROOT.rglob("*.lua"):
    text = lua.read_text()
    for m in req_re.finditer(text):
        expr = m.group(1).strip()
        if "script" not in expr:
            continue
        checked += 1
        cur = lua
        # strip .lua / .server.lua / .client.lua to module folder identity
        name = lua.name
        if name.endswith(".server.lua"):
            cur_mod = lua.parent / name[: -len(".server.lua")]
        elif name.endswith(".client.lua"):
            cur_mod = lua.parent / name[: -len(".client.lua")]
        else:
            cur_mod = lua.with_suffix("")
        # we resolve from the script instance: for Foo.lua, script is the module, script.Parent is folder
        node = lua.parent  # script.Parent
        parts = [p.strip() for p in expr.split(":WaitForChild")[0].split(".")]
        # parts start with script or script.Parent...
        if parts[0] != "script":
            continue
        node = lua  # start at script file conceptually
        # script -> the module file's "instance" is the module, parent is directory
        ok = True
        rest = parts[1:]
        loc = lua.parent  # after first .Parent we'll go up; treat script as file, .Parent as dir
        # reinterpret: walk from script
        cursor_is_file = True
        cursor = lua
        for part in rest:
            if part == "Parent":
                if cursor_is_file:
                    cursor = cursor.parent
                    cursor_is_file = False
                else:
                    cursor = cursor.parent
            else:
                # child module
                if cursor_is_file:
                    ok = False
                    break
                child = cursor / part
                found = file_for(child)
                if found:
                    cursor = found
                    cursor_is_file = True
                elif child.is_dir():
                    cursor = child
                    cursor_is_file = False
                else:
                    ok = False
                    break
        if not ok:
            fails.append(f"{lua.relative_to(ROOT)} -> {expr}")

print(f"checked {checked} script-relative requires")
if fails:
    print("MISSING:")
    for f in fails:
        print(" ", f)
    raise SystemExit(1)
print("ok")
