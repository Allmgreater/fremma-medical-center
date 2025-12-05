
````markdown name=REORG.md
# Repository reorganization for fremma-medical-center

This change provides a script (restructure.sh) that reorganizes the repository into a simple `public/` layout and consolidates assets under `public/assets/`. The script moves HTML files to `public/` and standardizes CSS/JS/images/fonts/plugins locations.

Why use this script
- Many project assets are currently at the repository root and HTML files reference nested plugin paths (e.g. `plugins/...`) that don't exist in the same structure; this causes styling and images to not load when serving the HTML.
- The script performs non-destructive moves (uses `mv -n` so existing files are not overwritten) and updates HTML references so pages will load assets from `public/assets/...`.
- Run locally so you can inspect and approve the changes before committing.

What the script does
- Creates `public/` and `public/assets/{css,js,images,plugins,fonts}`.
- Moves top-level asset files (CSS, JS, fonts, images) into the `public/assets/` folders.
- Moves `.html` pages into `public/`.
- Updates asset paths inside the moved HTML files (e.g. `css/style.css` → `assets/css/style.css`, `plugins/...` → `assets/plugins/...`, `images/...` → `assets/images/...`).
- Leaves a safe migration where you can check `public/` in a browser before committing.

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
     git add public/ .gitignore REORG.md restructure.sh
     git commit -m "Reorganize repo: move HTML to public/ and assets to public/assets/"
     git push --set-upstream origin reorg-structure
   - Open a PR and review.

Notes and next steps
- The script aims to handle the common layout mismatches that caused styles/images to not display. You should still manually inspect pages after running.
- After reorganization, consider:
  - Adding package.json and managing vendor libs via npm to avoid committing large vendor bundles.
  - Adding a build step to generate minified CSS/JS and optimize images.
  - Adding CI (GitHub Actions) to run build on every push and deploy the `public/` directory automatically.
- If you prefer that I perform the branch + commit and open a PR for you, tell me and provide permission for me to push changes to the repository (or I can provide the exact git commands and patch for you to run locally).

