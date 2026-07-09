from pathlib import Path
root1 = Path(r'c:/Users/USER/Downloads/flutter-project-assistance')
root2 = Path(r'c:/Users/USER/Desktop/smart_fish_feeder')
ignore_dirs = {'.git', '.dart_tool', 'build', 'android/.gradle', 'ios/Pods', '.idea', '.vscode', '.flutter-plugins-dependencies'}
ignore_files = {'.DS_Store', 'pubspec.lock'}


def walk(root):
    for p in root.rglob('*'):
        if p.is_dir():
            continue
        rel = p.relative_to(root)
        parts = rel.parts
        if any(part in ignore_dirs for part in parts):
            continue
        if p.name in ignore_files:
            continue
        yield rel

files1 = set(walk(root1))
files2 = set(walk(root2))
print('ONLY_IN_SOURCE')
for rel in sorted(files1 - files2):
    print(rel)
print('ONLY_IN_WORKSPACE')
for rel in sorted(files2 - files1):
    print(rel)
print('CHANGED')
for rel in sorted(files1 & files2):
    p1 = root1 / rel
    p2 = root2 / rel
    try:
        if p1.read_bytes() != p2.read_bytes():
            print(rel)
    except Exception as e:
        print(f'{rel} (read error: {e})')
