#!/usr/bin/env python3
"""Contact sheet of all key app icons — run before a release build.

Usage: python3 scripts/icon_preview.py [project_root]
Output: /tmp/icon_preview.png (also opened in Preview on macOS).
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

FILES = [
    ('assets/app_icon.png', 'app icon (source)'),
    ('assets/splash_logo.png', 'splash (source)'),
    ('assets/notification_icon.png', 'notif asset'),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 'iOS 1024'),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png', 'iOS 120'),
    ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', 'iOS splash'),
    ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 'Android launcher'),
    ('android/app/src/main/res/drawable-xxxhdpi/ic_notification_pulpo.png', 'Android notif large'),
    ('android/app/src/main/res/drawable-xxxhdpi/ic_stat_pulpo.png', 'Android status bar'),
    ('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png', 'macOS 256'),
]

def main(root: Path) -> None:
    cell, cols = 200, 5
    rows = (len(FILES) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * cell, rows * (cell + 26)), (70, 70, 74))
    d = ImageDraw.Draw(sheet)
    for i, (rel, label) in enumerate(FILES):
        f = root / rel
        im = Image.open(f).convert('RGBA')
        im.thumbnail((cell - 10, cell - 10))
        bg = Image.new('RGBA', (cell, cell), (90, 90, 94, 255))
        bg.paste(im, ((cell - im.width) // 2, (cell - im.height) // 2), im)
        x, y = (i % cols) * cell, (i // cols) * (cell + 26)
        sheet.paste(bg.convert('RGB'), (x, y))
        d.text((x + 6, y + cell + 6), label, fill=(255, 255, 255))
    out = Path('/tmp/icon_preview.png')
    sheet.save(out)
    print(f'saved {out}')
    if sys.platform == 'darwin':
        import subprocess
        subprocess.run(['open', str(out)])

if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    main(root)
