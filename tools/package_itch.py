"""Package a completed Godot Web export for itch.io."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import shutil

root = Path(__file__).resolve().parents[1]
web = root / 'release/web'
kit = root / 'release/itch-kit'
kit.mkdir(parents=True, exist_ok=True)
shutil.copy2(root / 'docs/ITCH-IO.txt', kit / 'ITCH-IO.txt')
for license_file in (root / 'assets/audio').glob('LICENSE-*.txt'):
    shutil.copy2(license_file, web / license_file.name)

build_zip = kit / 'art-of-peace-web.zip'
with ZipFile(build_zip, 'w', ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(web.iterdir()):
        if path.is_file() and path.suffix != '.import':
            archive.write(path, path.name)
with ZipFile(build_zip) as archive:
    assert archive.testzip() is None
    assert 'index.html' in archive.namelist()
    assert {'index.js', 'index.wasm', 'index.pck'} <= set(archive.namelist())
    assert all('/' not in name for name in archive.namelist())
    print(f'Browser ZIP verified: {build_zip.stat().st_size / 1024 / 1024:.1f} MB')

for name in ['cover.png', 'screenshot-gameplay.png', 'screenshot-characters.png']:
    assert (kit / name).is_file(), f'Missing marketing asset: {name}'
with ZipFile(root / 'release/itch-upload-kit.zip', 'w', ZIP_DEFLATED) as archive:
    for path in sorted(kit.iterdir()):
        if path.is_file() and path.suffix != '.import':
            archive.write(path, path.name)
print('Complete upload kit: release/itch-upload-kit.zip')
