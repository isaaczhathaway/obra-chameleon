#!/usr/bin/env bash

set -euo pipefail

MODE="${1:---tracked}"
FAILED=0
SENSITIVE_PATTERN='(/home/[[:alnum:]_.-]+|isaaczhathaway@[g]mail\.com|g[h]p_[[:alnum:]]+|github_p[a]t_[[:alnum:]_]+|-----BEGIN [A-Z ]*PRIVATE K[E]Y-----)'

die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

case "$MODE" in
	--staged|--tracked)
		;;
	*)
		die "Usage: scripts/audit-repository.sh [--staged|--tracked]"
		;;
esac

command -v git >/dev/null 2>&1 || die "git is required"
command -v rg >/dev/null 2>&1 || die "ripgrep (rg) is required"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "run this script inside the repository"

FILES=()
if [[ "$MODE" == "--staged" ]]; then
	mapfile -d '' FILES < <(git diff --cached --name-only --diff-filter=ACMR -z)
else
	mapfile -d '' FILES < <(git ls-files -z)
fi

for file in "${FILES[@]}"; do
	case "$file" in
		.gitignore|.gitattributes|LICENSE|README.md|CHANGELOG.md|CONTRIBUTING.md)
			;;
		.github/*|.githooks/*)
			;;
		assets/README.md|assets/screenshots/*.png)
			;;
		docs/compatibility.md|docs/packaging.md|docs/shader-design.md|docs/testing.md)
			;;
		reshade/Presets/Meccha_ObraDinn_Debug.ini|reshade/Presets/Meccha_ObraDinn_Default.ini)
			;;
		reshade/Presets/Meccha_ObraDinn_HighContrast.ini|reshade/Presets/Meccha_ObraDinn_Performance.ini)
			;;
		reshade/Presets/Meccha_ObraDinn_SoftDither.ini|reshade/Shaders/MecchaCommon.fxh)
			;;
		reshade/Shaders/MecchaObraDinn.fx|reshade/Shaders/MecchaDiagnostics/MecchaColorDiagnostics.fx)
			;;
		reshade/Shaders/MecchaDiagnostics/MecchaDepthDiagnostics.fx|reshade/Shaders/MecchaDiagnostics/MecchaTrivial.fx)
			;;
		scripts/audit-repository.sh|scripts/build-release.sh|scripts/package/*)
			;;
		*)
			printf 'DISALLOWED PATH: %s\n' "$file" >&2
			FAILED=1
			continue
			;;
	esac

	lower_file="${file,,}"
	case "$lower_file" in
		*.dll|*.exe|*.pak|*.ucas|*.utoc|*.reg|*.log|*.cache|*.zip|backups/*|test-results/*|chameleon/*|engine/*)
			printf 'PROHIBITED FILE TYPE OR TREE: %s\n' "$file" >&2
			FAILED=1
			continue
			;;
	esac

	[[ "$lower_file" == *.png ]] && continue
	if [[ "$MODE" == "--staged" ]]; then
		if git show ":$file" | rg -n --no-heading --color never "$SENSITIVE_PATTERN"; then
			printf 'SENSITIVE CONTENT: %s\n' "$file" >&2
			FAILED=1
		fi
	elif rg -n --no-heading --color never "$SENSITIVE_PATTERN" -- "$file"; then
		printf 'SENSITIVE CONTENT: %s\n' "$file" >&2
		FAILED=1
	fi
done

(( FAILED == 0 )) || die "repository audit failed"
printf 'Repository audit passed for %d %s file(s).\n' "${#FILES[@]}" "${MODE#--}"
