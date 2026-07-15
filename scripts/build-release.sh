#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
GAME_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
PACKAGE_SOURCE="$SCRIPT_DIR/package"
PACKAGE_NAME="Obra Chameleon"
VERSION="0.2"
ARCHIVE="$GAME_ROOT/Obra Chameleon v${VERSION}.zip"
STAGE_PARENT=""
FORCE=0

die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

cleanup() {
	if [[ -n "$STAGE_PARENT" && -d "$STAGE_PARENT" ]]; then
		rm -rf -- "$STAGE_PARENT"
	fi
}

if [[ "${1:-}" == "--force" ]]; then
	FORCE=1
	shift
fi
(( $# == 0 )) || die "Usage: scripts/build-release.sh [--force]"

for command_name in jq sha256sum zip zipinfo; do
	command -v "$command_name" >/dev/null 2>&1 || die "Required build command not found: $command_name"
done

if [[ -e "$ARCHIVE" && $FORCE -ne 1 ]]; then
	die "Archive already exists: $ARCHIVE. Use --force to replace this project-generated archive."
fi

STAGE_PARENT="$(mktemp -d -t obra-chameleon-release.XXXXXX)"
trap cleanup EXIT
STAGE_ROOT="$STAGE_PARENT/$PACKAGE_NAME"

mkdir -p -- \
	"$STAGE_ROOT/common/Presets" \
	"$STAGE_ROOT/common/Shaders" \
	"$STAGE_ROOT/ubuntu" \
	"$STAGE_ROOT/bazzite" \
	"$STAGE_ROOT/windows"

cp -a -- "$PACKAGE_SOURCE/README.md" "$STAGE_ROOT/README.md"
cp -a -- "$GAME_ROOT/LICENSE" "$STAGE_ROOT/LICENSE"
cp -a -- "$PACKAGE_SOURCE/common/ReShade.ini" "$STAGE_ROOT/common/ReShade.ini"
cp -a -- "$PACKAGE_SOURCE/common/install-linux-common.sh" "$STAGE_ROOT/common/install-linux-common.sh"
cp -a -- "$GAME_ROOT/reshade/Presets/." "$STAGE_ROOT/common/Presets/"
cp -a -- "$GAME_ROOT/reshade/Shaders/." "$STAGE_ROOT/common/Shaders/"
cp -a -- "$PACKAGE_SOURCE/ubuntu/." "$STAGE_ROOT/ubuntu/"
cp -a -- "$PACKAGE_SOURCE/bazzite/." "$STAGE_ROOT/bazzite/"
cp -a -- "$PACKAGE_SOURCE/windows/." "$STAGE_ROOT/windows/"

chmod +x -- \
	"$STAGE_ROOT/common/install-linux-common.sh" \
	"$STAGE_ROOT/ubuntu/install.sh" \
	"$STAGE_ROOT/bazzite/install.sh"

(
	cd -- "$STAGE_ROOT"
	while IFS= read -r -d '' file; do
		sha256sum -- "$file"
	done < <(find common -type f ! -name 'PAYLOAD-SHA256SUMS' ! -name 'manifest.json' -print0 | sort -z)
) > "$STAGE_ROOT/common/PAYLOAD-SHA256SUMS"

(
	cd -- "$STAGE_ROOT"
	while IFS= read -r -d '' file; do
		sha256sum -- "$file"
	done < <(find . -type f ! -name 'SHA256SUMS' ! -name 'manifest.json' -print0 | sort -z)
) > "$STAGE_ROOT/SHA256SUMS"

files_json="$(
	cd -- "$STAGE_ROOT"
	while IFS= read -r -d '' file; do
		jq -n \
			--arg path "${file#./}" \
			--arg sha256 "$(sha256sum -- "$file" | awk '{ print $1 }')" \
			'{path: $path, sha256: $sha256}'
	done < <(find . -type f ! -name 'manifest.json' -print0 | sort -z) | jq -s '.'
)"

jq -n \
	--arg name "$PACKAGE_NAME" \
	--arg version "$VERSION" \
	--arg app_id "4704690" \
	--arg executable "Chameleon/Binaries/Win64/PenguinHotel-Win64-Shipping.exe" \
	--arg reshade_version "6.7.3" \
	--arg reshade_setup_url "https://reshade.me/downloads/ReShade_Setup_6.7.3.exe" \
	--arg reshade_setup_sha256 "56791fd065358e899c581ebefe2ad871399b7c7ae83fb85e1154c08a75a44147" \
	--arg reshade_dll_sha256 "059168b9d8aaa694a02a64342409fa26dfdf335035f2c0184cc61581deffc3bc" \
	--arg default_preset "common/Presets/Meccha_ObraDinn_Default.ini" \
	--argjson files "$files_json" \
	'{
		name: $name,
		version: $version,
		steamAppId: $app_id,
		expectedGameExecutable: $executable,
		reshade: {
			version: $reshade_version,
			setupUrl: $reshade_setup_url,
			setupSha256: $reshade_setup_sha256,
			runtimeDllSha256: $reshade_dll_sha256,
			bundled: false
		},
		defaultPreset: $default_preset,
		files: $files
	}' > "$STAGE_ROOT/manifest.json"

if (( FORCE )); then
	rm -f -- "$ARCHIVE"
fi

(
	cd -- "$STAGE_PARENT"
	zip -X -q -r "$ARCHIVE" "$PACKAGE_NAME"
)

while IFS= read -r archived_path; do
	case "$archived_path" in
		*.dll|*ReShade_Setup*.exe)
			die "Third-party ReShade binary was accidentally packaged: $archived_path"
			;;
	esac
done < <(zipinfo -1 "$ARCHIVE")

printf 'Built: %s\n' "$ARCHIVE"
printf 'SHA-256: %s\n' "$(sha256sum -- "$ARCHIVE" | awk '{ print $1 }')"
