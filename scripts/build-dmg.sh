#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_developer_dir() {
  local candidates=(
    "/Applications/Xcode.app/Contents/Developer"
    "/Volumes/Macintosh HD/Applications/Xcode.app/Contents/Developer"
    "/Volumes/pmbb/Applications/Xcode.app/Contents/Developer"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  if resolved_developer_dir="$(resolve_developer_dir)"; then
    export DEVELOPER_DIR="$resolved_developer_dir"
  fi
fi

APP_PRODUCT_NAME="AppIconExporterApp"
APP_BUNDLE_NAME="应用图标导出器"
EXECUTABLE_NAME="AppIconExporterApp"
BUNDLE_IDENTIFIER="com.shuai.app-icon-exporter.app"
MINIMUM_SYSTEM_VERSION="14.0"
BUNDLE_VERSION="${BUNDLE_VERSION:-$(date +%Y%m%d%H%M)}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ICON_SOURCE_PATH="$PROJECT_ROOT/Assets/app-icon-compact.png"
ICON_FILE_NAME="AppIcon.icns"

BUILD_DIR="$PROJECT_ROOT/.build"
RELEASE_DIR="$BUILD_DIR/release"
ARTIFACTS_DIR="$PROJECT_ROOT/dist"
STAGING_DIR="$ARTIFACTS_DIR/dmg-staging"
APP_BUNDLE_PATH="$ARTIFACTS_DIR/${APP_BUNDLE_NAME}.app"
DMG_PATH="$ARTIFACTS_DIR/${APP_BUNDLE_NAME}.dmg"
EXECUTABLE_PATH="$RELEASE_DIR/$EXECUTABLE_NAME"
PLIST_PATH="$APP_BUNDLE_PATH/Contents/Info.plist"
PKGINFO_PATH="$APP_BUNDLE_PATH/Contents/PkgInfo"
ICONSET_PATH="$BUILD_DIR/AppIcon.iconset"
ICNS_BUILD_PATH="$BUILD_DIR/AppIcon.icns"
ICNS_OUTPUT_PATH="$APP_BUNDLE_PATH/Contents/Resources/$ICON_FILE_NAME"
LEGACY_APP_BUNDLE_PATH="$ARTIFACTS_DIR/App Icon Exporter.app"
LEGACY_DMG_PATH="$ARTIFACTS_DIR/AppIconExporter.dmg"
LEGACY_ICON_ARTIFACT_PATH="$ARTIFACTS_DIR/AppIcon.icns"

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
}

require_command swift
require_command hdiutil
require_command codesign
require_command iconutil
require_command sips

mkdir -p "$ARTIFACTS_DIR"
trap 'rm -rf "$STAGING_DIR" "$ICONSET_PATH" "$ICNS_BUILD_PATH"' EXIT

LSREGISTER_PATH="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

unregister_stale_bundle_paths() {
  [[ -x "$LSREGISTER_PATH" ]] || return 0

  local search_roots=(
    "$ARTIFACTS_DIR"
    "/Applications"
    "$HOME/.Trash"
    "/Volumes"
  )

  local root
  local stale_path
  for root in "${search_roots[@]}"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r stale_path; do
      [[ "$stale_path" == "$APP_BUNDLE_PATH" ]] && continue
      "$LSREGISTER_PATH" -u "$stale_path" >/dev/null 2>&1 || true
    done < <(find "$root" -maxdepth 4 -type d -name "${APP_BUNDLE_NAME}.app" -print 2>/dev/null)
  done
}

create_iconset() {
  local source_png="$1"
  local iconset_path="$2"

  rm -rf "$iconset_path"
  mkdir -p "$iconset_path"

  sips -z 16 16     "$source_png" --out "$iconset_path/icon_16x16.png" >/dev/null
  sips -z 32 32     "$source_png" --out "$iconset_path/icon_16x16@2x.png" >/dev/null
  sips -z 32 32     "$source_png" --out "$iconset_path/icon_32x32.png" >/dev/null
  sips -z 64 64     "$source_png" --out "$iconset_path/icon_32x32@2x.png" >/dev/null
  sips -z 128 128   "$source_png" --out "$iconset_path/icon_128x128.png" >/dev/null
  sips -z 256 256   "$source_png" --out "$iconset_path/icon_128x128@2x.png" >/dev/null
  sips -z 256 256   "$source_png" --out "$iconset_path/icon_256x256.png" >/dev/null
  sips -z 512 512   "$source_png" --out "$iconset_path/icon_256x256@2x.png" >/dev/null
  sips -z 512 512   "$source_png" --out "$iconset_path/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$source_png" --out "$iconset_path/icon_512x512@2x.png" >/dev/null
}

if [[ ! -f "$ICON_SOURCE_PATH" ]]; then
  echo "Missing icon source PNG: $ICON_SOURCE_PATH" >&2
  exit 1
fi

echo "使用 SwiftPM 构建 Release 可执行文件..."
(
  cd "$PROJECT_ROOT"
  swift build -c release --product "$APP_PRODUCT_NAME"
)

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Expected executable not found: $EXECUTABLE_PATH" >&2
  exit 1
fi

echo "清理旧产物..."
rm -rf "$LEGACY_APP_BUNDLE_PATH" "$LEGACY_DMG_PATH" "$LEGACY_ICON_ARTIFACT_PATH"

echo "生成应用图标资源..."
create_iconset "$ICON_SOURCE_PATH" "$ICONSET_PATH"
iconutil -c icns "$ICONSET_PATH" -o "$ICNS_BUILD_PATH"

echo "创建 .app 包结构..."
rm -rf "$APP_BUNDLE_PATH" "$STAGING_DIR" "$DMG_PATH"
mkdir -p \
  "$APP_BUNDLE_PATH/Contents/MacOS" \
  "$APP_BUNDLE_PATH/Contents/Resources" \
  "$APP_BUNDLE_PATH/Contents/Resources/zh-Hans.lproj" \
  "$STAGING_DIR"

cp "$EXECUTABLE_PATH" "$APP_BUNDLE_PATH/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ICNS_BUILD_PATH" "$ICNS_OUTPUT_PATH"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleAllowMixedLocalizations</key>
  <true/>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh-Hans</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_IDENTIFIER</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>zh-Hans</string>
  </array>
  <key>CFBundleName</key>
  <string>$APP_BUNDLE_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_BUNDLE_NAME</string>
  <key>CFBundleIconFile</key>
  <string>${ICON_FILE_NAME%.icns}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MINIMUM_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$PKGINFO_PATH"

cat > "$APP_BUNDLE_PATH/Contents/Resources/zh-Hans.lproj/InfoPlist.strings" <<EOF
"CFBundleDisplayName" = "$APP_BUNDLE_NAME";
"CFBundleName" = "$APP_BUNDLE_NAME";
EOF

echo "为应用签名: $SIGN_IDENTITY"
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_BUNDLE_PATH"

if [[ -x "$LSREGISTER_PATH" ]]; then
  echo "刷新 LaunchServices 注册..."
  unregister_stale_bundle_paths
  "$LSREGISTER_PATH" -f "$APP_BUNDLE_PATH" >/dev/null 2>&1 || true
fi
touch "$ICNS_OUTPUT_PATH" "$PLIST_PATH" "$APP_BUNDLE_PATH"

echo "准备 DMG 内容..."
cp -R "$APP_BUNDLE_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "创建 DMG..."
hdiutil create \
  -volname "$APP_BUNDLE_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "完成。"
echo "App bundle: $APP_BUNDLE_PATH"
echo "DMG: $DMG_PATH"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  echo "说明：当前使用的是 ad-hoc 签名，其他机器上的 Gatekeeper 很可能会拒绝该构建。"
  echo "如果要分发，请使用 SIGN_IDENTITY='Developer ID Application: ...' 重新打包。"
fi
