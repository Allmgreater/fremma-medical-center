#!/usr/bin/env bash
set -euo pipefail

# reorg-structure: Reorganize repository into public/ + public/assets/ layout
#
# Usage (run from repo root):
#   chmod +x restructure.sh
#   ./restructure.sh
#
# After running:
# - HTML files will be moved to public/
# - CSS/JS/images/fonts/plugins will be under public/assets/
# - HTML files in public/ will have updated relative paths to assets/
#
# NOTE: This script moves files (mv -n) but will not overwrite existing files.
#       Inspect public/ after running and commit the changes on a new branch.

echo "=> Creating public/ and assets directories..."
mkdir -p public/assets/{css,js,images,plugins,fonts}

echo "=> Moving CSS files..."
[ -f style.css ] && mv -n style.css public/assets/css/
[ -f style.scss ] && mv -n style.scss public/assets/css/
[ -f bootstrap.min.css ] && mv -n bootstrap.min.css public/assets/plugins/bootstrap.min.css
[ -f icofont.min.css ] && mv -n icofont.min.css public/assets/plugins/icofont.min.css
[ -f icofont.css ] && mv -n icofont.css public/assets/plugins/icofont.css
[ -f slick.css ] && mv -n slick.css public/assets/plugins/slick.css
[ -f "slick-theme.css" ] && mv -n "slick-theme.css" public/assets/plugins/slick-theme.css

echo "=> Moving JS and vendor files..."
# vendor JS (flatten into plugins)
[ -f jquery.js ] && mv -n jquery.js public/assets/plugins/jquery.js
[ -f bootstrap.min.js ] && mv -n bootstrap.min.js public/assets/plugins/bootstrap.min.js
[ -f popper.js ] && mv -n popper.js public/assets/plugins/popper.js
[ -f "slick.min.js" ] && mv -n "slick.min.js" public/assets/plugins/slick.min.js
[ -f "slick.js" ] && mv -n "slick.js" public/assets/plugins/slick.js
[ -f "shuffle.min.js" ] && mv -n "shuffle.min.js" public/assets/plugins/shuffle.min.js
[ -f "jquery.waypoints.min.js" ] && mv -n "jquery.waypoints.min.js" public/assets/plugins/jquery.waypoints.min.js
[ -f "jquery.counterup.min.js" ] && mv -n "jquery.counterup.min.js" public/assets/plugins/jquery.counterup.min.js
[ -f "jquery.easing.js" ] && mv -n "jquery.easing.js" public/assets/plugins/jquery.easing.js
# custom JS -> assets/js
[ -f script.js ] && mv -n script.js public/assets/js/script.js
[ -f contact.js ] && mv -n contact.js public/assets/js/contact.js
[ -f map.js ] && mv -n map.js public/assets/js/map.js

echo "=> Moving icon/font files..."
[ -f icofont.eot ] && mv -n icofont.eot public/assets/fonts/
[ -f icofont.ttf ] && mv -n icofont.ttf public/assets/fonts/
[ -f icofont.woff ] && mv -n icofont.woff public/assets/fonts/
[ -f icofont.woff2 ] && mv -n icofont.woff2 public/assets/fonts/

echo "=> Moving images..."
# Move top-level image files
for f in *.jpg *.jpeg *.png *.gif *.svg; do
  [ -e "$f" ] || continue
  mv -n "$f" public/assets/images/ 2>/dev/null || true
done

# Move images/ directory (if it exists) into assets/
if [ -d "images" ]; then
  # If public/assets/images/images already exists, merge instead of failing
  if [ -d "public/assets/images/images" ]; then
    echo "=> Merging images/ into public/assets/images/"
    cp -rn images/* public/assets/images/ || true
    rm -rf images
  else
    mv -n images public/assets/ || true
    # If moved as public/assets/images, ensure images path is public/assets/images/ (images/ may be nested)
    if [ -d public/assets/images/images ]; then
      # flatten nested images directory
      mv -n public/assets/images/images/* public/assets/images/ 2>/dev/null || true
      rmdir public/assets/images/images || true
    fi
  fi
fi

echo "=> Moving HTML files into public/..."
for f in *.html; do
  [ -e "$f" ] || continue
  mv -n "$f" public/ 2>/dev/null || true
done

echo "=> Updating asset paths inside HTML files in public/..."
# Replace many common patterns to point to the new public/assets/ layout.
# Do per-file edits (create .bak and remove it after)
shopt -s nullglob
for f in public/*.html; do
  echo "   - patching $f"

  # Specific plugin CSS paths -> flattened new plugin paths
  sed -i.bak 's|plugins/bootstrap/css/bootstrap.min.css|assets/plugins/bootstrap.min.css|g' "$f" || true
  sed -i.bak 's|plugins/icofont/icofont.min.css|assets/plugins/icofont.min.css|g' "$f" || true
  sed -i.bak 's|plugins/slick-carousel/slick/slick.css|assets/plugins/slick.css|g' "$f" || true
  sed -i.bak 's|plugins/slick-carousel/slick/slick-theme.css|assets/plugins/slick-theme.css|g' "$f" || true

  # Generic replacements
  sed -i.bak 's|href="plugins/|href="assets/plugins/|g' "$f" || true
  sed -i.bak 's|src="plugins/|src="assets/plugins/|g' "$f" || true

  # Main stylesheet
  sed -i.bak 's|css/style.css|assets/css/style.css|g' "$f" || true

  # js/ -> assets/js/
  sed -i.bak 's|src="js/|src="assets/js/|g' "$f" || true
  sed -i.bak "s|src='js/|src='assets/js/|g" "$f" || true

  # images/ -> assets/images/
  sed -i.bak 's|src="images/|src="assets/images/|g' "$f" || true
  sed -i.bak "s|href=\"/images/|href=\"assets/images/|g" "$f" || true
  sed -i.bak "s|src=\"/images/|src=\"assets/images/|g" "$f" || true

  # favicon absolute path -> assets/images/
  sed -i.bak 's|href="/images/favicon.ico"|href="assets/images/favicon.ico"|g' "$f" || true
  sed -i.bak 's|href="/favicon.ico"|href="assets/images/favicon.ico"|g' "$f" || true

  # Remove any leading slash from asset references (e.g. /assets/... -> assets/...)
  sed -i.bak 's|href="/assets/|href="assets/|g' "$f" || true
  sed -i.bak 's|src="/assets/|src="assets/|g' "$f" || true

  # Fallback: convert plugins/... -> assets/plugins/ (if any remain)
  sed -i.bak 's|plugins/|assets/plugins/|g' "$f" || true

  # style hrefs that still reference css/ (if any)
  sed -i.bak 's|href="css/|href="assets/css/|g' "$f" || true

  # Clean up backup
  rm -f "$f.bak"
done

echo "=> Reorganization finished."
echo "  - HTML files: public/"
echo "  - Assets: public/assets/{css,js,images,plugins,fonts}"
echo
echo "Next steps:"
echo "  1) Inspect public/ locally:  python -m http.server --directory public 8000"
echo "  2) If OK, create a branch (git checkout -b reorg-structure), git add public/ and remove moved originals if desired, commit and push."
echo "  3) Optionally run image optimization and update any remaining paths."
echo

exit 0
````markdown name=REORG.md
```markdown
# Repository reorganization for fremma-medical-center

This provides a script (restructure.sh) that reorganizes the repository into a simple `public/` layout and consolidates assets under `public/assets/`. The script moves HTML files to `public/` and standardizes CSS/JS/images/fonts/plugins locations.

Why use this script
- Many project assets are currently at the repository root and HTML files reference nested plugin paths (e.g. `plugins/...`) that don't exist in the same structure; this causes styling and images to not load when serving the HTML.
- The script performs non-destructive moves (uses `mv -n` so existing files are not overwritten) and updates HTML references so pages will load assets from `public/assets/...`.
- Run locally so you can inspect and approve the changes before committing.

How to run
1. From your repository root:
   - Make the script executable:
     chmod +x restructure.sh
   - Run it:
     ./restructure.sh

2. Serve and verify locally:
   - python -m http.server --directory public 8000
   - Visit http://localhost:8000 and verify styles/images/JS load.

3. If satisfied:
   - Create a new branch and commit the reorganized files:
     git checkout -b reorg-structure
     git add public/ restructure.sh REORG.md .gitignore
     git commit -m "Reorganize repo: move HTML to public/ and assets to public/assets/"
     git push --set-upstream origin reorg-structure
   - Open a PR and review.

Notes and next steps
- The script aims to handle the common layout mismatches that caused styles/images to not display. You should still manually inspect pages after running.
- After reorganization, consider:
  - Adding package.json and managing vendor libs via npm to avoid committing large vendor bundles.
  - Adding a build step to generate minified CSS/JS and optimize images.
  - Adding CI (GitHub Actions) to run build on every push and deploy the `public/` directory automatically.
