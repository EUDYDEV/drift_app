import pathlib
import re

root = pathlib.Path(r"c:\Users\eudyp\drift_app")
pattern = re.compile(r"\.withOpacity\(")
count = 0
for fp in root.glob("lib/**/*.dart"):
    text = fp.read_text(encoding="utf-8")
    if ".withOpacity(" in text:
        new = pattern.sub(".withValues(alpha:", text)
        if new != text:
            fp.write_text(new, encoding="utf-8")
            count += 1
print(f"Updated {count} files")
