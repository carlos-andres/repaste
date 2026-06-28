#!/usr/bin/env bash
# Build + Developer ID signing + notarization + staple of Repaste for distribution.
# Recipe verified end-to-end (notarization Accepted + Gatekeeper accepted).
#
# Requirements (one-time):
#   - xcodegen
#   - "Developer ID Application" certificate for your team in the keychain
#   - a stored notarization profile (NOTARY_PROFILE overrides the name; default repaste-notary):
#       xcrun notarytool store-credentials "repaste-notary" --apple-id <your-apple-id> --team-id <your-team-id>
set -euo pipefail

# DEBUG=1 bin/release.sh → trace every command with its expansions (max verbosity for debugging the pipeline).
[[ "${DEBUG:-0}" == "1" ]] && set -x

PROFILE="${NOTARY_PROFILE:-repaste-notary}"
DD="build-release"
APP="$DD/Build/Products/Release/Repaste.app"

# Notarize an artifact; if it doesn't end "Accepted", fetch Apple's log with the reason — without it
# "Invalid" says nothing. Capture the output even if notarytool fails, so the id stays readable.
notarize() {
    local artifact="$1" out id
    out=$(xcrun notarytool submit "$artifact" --keychain-profile "$PROFILE" --wait 2>&1) || true
    echo "$out"
    if ! grep -q "status: Accepted" <<<"$out"; then
        id=$(sed -n 's/^[[:space:]]*id: \([0-9a-fA-F-]*\).*/\1/p' <<<"$out" | head -1)
        [[ -n "$id" ]] && { echo "✗ Notarization NOT Accepted — Apple log:"; xcrun notarytool log "$id" --keychain-profile "$PROFILE"; }
        return 1
    fi
}

cd "$(dirname "$0")/.."

echo "› Generating project…"
xcodegen generate

echo "› Building Release (Developer ID + hardened runtime + timestamp)…"
rm -rf "$DD"
xcodebuild -scheme Repaste -configuration Release -derivedDataPath "$DD" build

echo "› Packaging for notarization…"
ditto -c -k --keepParent "$APP" "$DD/Repaste-notarize.zip"

echo "› Notarizing (waiting on Apple)…"
notarize "$DD/Repaste-notarize.zip"

echo "› Stapling ticket to the .app…"
xcrun stapler staple "$APP"

echo "› Verifying with Gatekeeper…"
spctl -a -t exec -vvv "$APP"

# Stapling modifies the .app on disk: the .dmg is built AFTER the .app is stapled,
# so the stapled app inside passes Gatekeeper even offline.
VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")
DMG="$DD/Repaste-$VERSION.dmg"
STAGE="$DD/dmg-stage"

echo "› Building the .dmg (stapled app + /Applications symlink)…"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/Repaste.app"   # ditto preserves the signature; cp -R breaks the bundle's xattrs
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Repaste $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

echo "› Signing the .dmg (Developer ID + timestamp)…"
codesign --sign "Developer ID Application" --timestamp --verbose "$DMG"

echo "› Notarizing the .dmg (waiting on Apple)…"
notarize "$DMG"

echo "› Stapling the ticket to the .dmg…"
xcrun stapler staple "$DMG"

echo "› Verifying the .dmg with Gatekeeper…"
spctl -a -t open --context context:primary-signature -vvv "$DMG"

echo "✓ Done: $DMG (stapled app inside + notarized, stapled .dmg)."
