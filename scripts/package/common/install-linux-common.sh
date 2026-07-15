#!/usr/bin/env bash

set -euo pipefail

RESHADER_VERSION="6.7.3"
RESHADER_SETUP_URL="https://reshade.me/downloads/ReShade_Setup_${RESHADER_VERSION}.exe"
RESHADER_SETUP_SHA256="56791fd065358e899c581ebefe2ad871399b7c7ae83fb85e1154c08a75a44147"
RESHADER_DLL_SHA256="059168b9d8aaa694a02a64342409fa26dfdf335035f2c0184cc61581deffc3bc"

COMMON_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGE_ROOT="$(cd -- "$COMMON_DIR/.." && pwd -P)"
GAME_ROOT="$(cd -- "$PACKAGE_ROOT/.." && pwd -P)"
PAYLOAD_DIR="$PACKAGE_ROOT/common"
RUNTIME_DIR="$GAME_ROOT/Chameleon/Binaries/Win64"
GAME_EXE="$RUNTIME_DIR/PenguinHotel-Win64-Shipping.exe"
PLATFORM_NAME="${OBRA_PLATFORM_NAME:-Linux}"

DRY_RUN=0
RESHADER_DLL=""
TEMP_DIR=""

log() {
	printf '%s\n' "$*"
}

warn() {
	printf 'WARNING: %s\n' "$*" >&2
}

die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

print_command() {
	printf 'DRY-RUN:'
	printf ' %q' "$@"
	printf '\n'
}

run() {
	if (( DRY_RUN )); then
		print_command "$@"
	else
		"$@"
	fi
}

usage() {
	cat <<EOF
Obra Chameleon v0.2 installer for $PLATFORM_NAME

Usage: install.sh [options]

Options:
	--dry-run             Validate and print changes without installing
	--reshade-dll PATH    Use a local official ReShade 6.7.3 ReShade64.dll
	--help                Show this help

This package must be extracted so that the "Obra Chameleon" directory is
directly inside the Meccha Chameleon game root.
EOF
}

file_sha256() {
	sha256sum -- "$1" | awk '{ print $1 }'
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

find_extractor() {
	local candidate

	for candidate in 7z 7zz; do
		if command -v "$candidate" >/dev/null 2>&1; then
			printf '%s\n' "$candidate"
			return
		fi
	done
	die "7-Zip command not found. Install either '7z' or '7zz', then retry."
}

verify_layout() {
	[[ -f "$GAME_ROOT/PenguinHotel.exe" ]] || die "PenguinHotel.exe was not found in: $GAME_ROOT"
	[[ -f "$GAME_EXE" ]] || die "Shipping executable was not found: $GAME_EXE"
	[[ -d "$GAME_ROOT/Engine" ]] || die "Unreal Engine directory was not found: $GAME_ROOT/Engine"
	[[ -d "$GAME_ROOT/Chameleon/Content/Paks" ]] || die "Packaged game content was not found"
	[[ -f "$PACKAGE_ROOT/manifest.json" ]] || die "Package manifest is missing; extract the complete ZIP again"
	[[ -f "$PAYLOAD_DIR/PAYLOAD-SHA256SUMS" ]] || die "Payload checksum file is missing"
}

verify_payload() {
	log "Verifying the shared shader payload..."
	(
		cd -- "$PACKAGE_ROOT"
		sha256sum --check --status common/PAYLOAD-SHA256SUMS
	) || die "Package payload checksum verification failed; extract a fresh copy of the ZIP"
}

game_is_running() {
	pgrep -f '[P]enguinHotel-Win64-Shipping.exe' >/dev/null 2>&1
}

preflight_target() {
	local source="$1"
	local target="$2"

	[[ -e "$target" ]] || return 0
	[[ -f "$target" ]] || die "Install target is not a regular file: $target"
	if (( DRY_RUN )) && [[ ! -f "$source" && "$target" == "$RUNTIME_DIR/dxgi.dll" ]] && [[ "$(file_sha256 "$target")" == "$RESHADER_DLL_SHA256" ]]; then
		return 0
	fi
	if [[ -f "$source" ]] && [[ "$(file_sha256 "$source")" == "$(file_sha256 "$target")" ]]; then
		return 0
	fi
	die "Existing file would be replaced: $target. Move or remove the existing ReShade installation before retrying."
}

install_file() {
	local source="$1"
	local target="$2"

	if [[ -f "$target" ]] && [[ "$(file_sha256 "$source")" == "$(file_sha256 "$target")" ]]; then
		log "Already installed: $target"
		return
	fi
	run mkdir -p -- "$(dirname -- "$target")"
	run cp -a -- "$source" "$target"
	if (( DRY_RUN )); then
		log "Would install: $target"
	else
		log "Installed: $target"
	fi
}

cleanup() {
	if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
		rm -rf -- "$TEMP_DIR"
	fi
}

obtain_reshade_runtime() {
	local setup extractor

	if [[ -n "$RESHADER_DLL" ]]; then
		[[ -f "$RESHADER_DLL" ]] || die "ReShade DLL was not found: $RESHADER_DLL"
	else
		require_command curl
		extractor="$(find_extractor)"
		if (( DRY_RUN )); then
			RESHADER_DLL="${TMPDIR:-/tmp}/Obra-Chameleon-dry-run/ReShade64.dll"
			print_command curl -fL --retry 3 -o "ReShade_Setup_${RESHADER_VERSION}.exe" "$RESHADER_SETUP_URL"
			print_command "$extractor" e -y "ReShade_Setup_${RESHADER_VERSION}.exe" ReShade64.dll
			return
		fi
		TEMP_DIR="$(mktemp -d -t obra-chameleon.XXXXXX)"
		setup="$TEMP_DIR/ReShade_Setup_${RESHADER_VERSION}.exe"
		log "Downloading the official ReShade $RESHADER_VERSION setup program..."
		curl -fL --retry 3 -o "$setup" "$RESHADER_SETUP_URL"
		[[ "$(file_sha256 "$setup")" == "$RESHADER_SETUP_SHA256" ]] || die "Official ReShade setup checksum mismatch"
		"$extractor" e -y "-o$TEMP_DIR" "$setup" ReShade64.dll >/dev/null
		RESHADER_DLL="$TEMP_DIR/ReShade64.dll"
	fi

	if (( DRY_RUN == 0 )); then
		[[ "$(file_sha256 "$RESHADER_DLL")" == "$RESHADER_DLL_SHA256" ]] || die "ReShade64.dll does not match the tested ReShade $RESHADER_VERSION runtime"
	fi
}

build_file_lists() {
	local source relative

	SOURCES=("$RESHADER_DLL" "$PAYLOAD_DIR/ReShade.ini")
	TARGETS=("$RUNTIME_DIR/dxgi.dll" "$RUNTIME_DIR/ReShade.ini")

	while IFS= read -r -d '' source; do
		relative="${source#"$PAYLOAD_DIR/Shaders/"}"
		SOURCES+=("$source")
		TARGETS+=("$RUNTIME_DIR/reshade-shaders/Shaders/$relative")
	done < <(find "$PAYLOAD_DIR/Shaders" -type f \( -name '*.fx' -o -name '*.fxh' \) -print0 | sort -z)

	while IFS= read -r -d '' source; do
		SOURCES+=("$source")
		TARGETS+=("$RUNTIME_DIR/$(basename -- "$source")")
	done < <(find "$PAYLOAD_DIR/Presets" -maxdepth 1 -type f -name '*.ini' -print0 | sort -z)
}

install_for_linux() {
	local index

	while (( $# )); do
		case "$1" in
			--dry-run)
				DRY_RUN=1
				shift
				;;
			--reshade-dll)
				(( $# >= 2 )) || die "--reshade-dll requires a path"
				RESHADER_DLL="$2"
				shift 2
				;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				die "Unknown option: $1"
				;;
		esac
	done

	require_command sha256sum
	require_command awk
	require_command find
	require_command pgrep
	verify_layout
	verify_payload
	game_is_running && die "Meccha Chameleon is running; close it before installation"
	trap cleanup EXIT
	obtain_reshade_runtime
	build_file_lists

	for (( index=0; index<${#SOURCES[@]}; index++ )); do
		preflight_target "${SOURCES[index]}" "${TARGETS[index]}"
	done

	log "Installing Obra Chameleon into: $RUNTIME_DIR"
	for (( index=0; index<${#SOURCES[@]}; index++ )); do
		if (( DRY_RUN )) && [[ ! -f "${SOURCES[index]}" ]]; then
			print_command cp -a -- "${SOURCES[index]}" "${TARGETS[index]}"
			continue
		fi
		install_file "${SOURCES[index]}" "${TARGETS[index]}"
	done

	if (( DRY_RUN )); then
		log "Dry run complete. No files were changed."
	else
		log "Installation complete."
	fi
	log ""
	log "REQUIRED STEAM LAUNCH OPTION"
	log 'WINEDLLOVERRIDES="dxgi=n,b" %command%'
	log ""
	log "Add that exact line in Steam: Meccha Chameleon > Properties > General > Launch Options."
	log "Without the launch option, ReShade will not load through Proton."
	log "Home opens ReShade, and Scroll Lock toggles the effect."
	warn "Use private or solo play while anti-cheat compatibility remains unconfirmed."
}
