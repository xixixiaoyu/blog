#!/usr/bin/env bash
set -euo pipefail

# === pre-commit: compress staged PNG/JPEG images ===
# - Only processes images that are staged for commit (added/modified)
# - Resizes very large images to a max dimension (default: 1600px)
# - Compresses PNG via pngquant, JPEG via jpegoptim
# - Re-adds changed files to the Git index to ensure compressed content is committed

MAX_DIM=${MAX_DIM:-1600}
PNG_QUALITY=${PNG_QUALITY:-65-80}
JPEG_QUALITY=${JPEG_QUALITY:-80}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}
has_npx() {
  command -v npx >/dev/null 2>&1
}

die() {
  echo "[pre-commit] $*" 1>&2
  exit 1
}

# If there are no staged images, exit early (don't block commits when deps are missing)
if ! git diff --cached --name-only --diff-filter=AM | grep -E -i '\.(png|jpe?g)$' >/dev/null; then
  exit 0
fi

# Check required tools only when there are images to process
missing=()
has_cmd sips || missing+=("sips")
has_cmd pngquant || missing+=("pngquant")
has_cmd jpegoptim || missing+=("jpegoptim")

# If pngquant/jpegoptim missing, but npx is available, we can fallback to squoosh-cli
if [ ${#missing[@]} -gt 0 ]; then
  if ! has_cmd sips; then
    echo "[pre-commit] 缺少 sips（macOS 内置），无法处理尺寸，终止提交。"
    exit 1
  fi
  if (! has_cmd pngquant || ! has_cmd jpegoptim) && has_npx; then
    echo "[pre-commit] 检测到缺少部分压缩工具，使用 npx @squoosh/cli 作为后备方案。"
  else
    echo "[pre-commit] 检测到已暂存的图片，但缺少依赖: ${missing[*]}"
    echo "请安装（macOS 示例）：brew install pngquant jpegoptim"
    exit 1
  fi
fi

resize_if_needed() {
  local f="$1"
  # Query dimensions using macOS built-in 'sips'
  local w h
  w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  if [ -n "$w" ] && [ -n "$h" ]; then
    if [ "$w" -gt "$MAX_DIM" ] || [ "$h" -gt "$MAX_DIM" ]; then
      # -Z: constrain to box of size MAX_DIM, keeping aspect ratio
      sips -Z "$MAX_DIM" "$f" >/dev/null
    fi
  fi
}

compress_png() {
  local f="$1"
  [ -f "$f" ] || return 0
  resize_if_needed "$f"
  if has_cmd pngquant; then
    # In-place compression; skip if result would be larger
    pngquant --quality "$PNG_QUALITY" --strip --skip-if-larger --force --output "$f" "$f"
  elif has_npx; then
    # Fallback to squoosh-cli (oxipng) writing to a temp dir, then move back
    tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t squoosh)
    npx --yes @squoosh/cli --oxipng '{"level":2}' -d "$tmpdir" "$f" >/dev/null
    mv -f "$tmpdir/$(basename "$f")" "$f"
    rm -rf "$tmpdir"
  fi
}

compress_jpeg() {
  local f="$1"
  [ -f "$f" ] || return 0
  resize_if_needed "$f"
  if has_cmd jpegoptim; then
    # In-place compression to target quality, strip metadata, progressive
    jpegoptim --max="$JPEG_QUALITY" --strip-all --all-progressive --quiet "$f" || true
  elif has_npx; then
    # Fallback to squoosh-cli (mozjpeg) writing to a temp dir, then move back
    tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t squoosh)
    # mozjpeg quality 80
    npx --yes @squoosh/cli --mozjpeg '{"quality":'"$JPEG_QUALITY"'}' -d "$tmpdir" "$f" >/dev/null
    mv -f "$tmpdir/$(basename "$f")" "$f"
    rm -rf "$tmpdir"
  fi
}

changed_any=false

# Iterate over staged image files (added/modified), robust to spaces via -z
git diff --cached --name-only --diff-filter=AM -z |
while IFS= read -r -d '' f; do
  case "$f" in
    *.png|*.PNG)
      compress_png "$f"
      ;;
    *.jpg|*.JPG|*.jpeg|*.JPEG)
      compress_jpeg "$f"
      ;;
    *)
      continue
      ;;
  esac

  # If file content changed, re-add to staging
  if ! git diff --quiet -- "$f"; then
    git add "$f"
    echo "[pre-commit] 已压缩并更新: $f"
    changed_any=true
  else
    echo "[pre-commit] 已优化但无变化: $f"
  fi
done

exit 0