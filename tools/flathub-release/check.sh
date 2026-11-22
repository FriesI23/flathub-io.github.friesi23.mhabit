#!/usr/bin/env bash
set -euo pipefail

tool_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_dir=$(cd -- "$tool_dir/../.." && pwd -P)
output_dir=$tool_dir/output
app_id=io.github.friesi23.mhabit
image=ghcr.io/flathub-infra/flatpak-github-actions:freedesktop-25.08@sha256:c91a88269eee8fcdd73ecf43064232fbebe27411f926f63f38bdf70c51f2ceae

if [[ ! -f $repo_dir/$app_id.yml ]]; then
    printf 'Cannot find the generated manifest %s.yml\n' "$app_id" >&2
    exit 1
fi
mkdir -p "$output_dir"

# Give OSTree writable storage for SDK updates and keep the checkout read-only.
docker run --rm --interactive --privileged \
    --volume /var/lib/flatpak \
    --mount "type=bind,source=$repo_dir,target=/input,readonly" \
    --mount "type=bind,source=$output_dir,target=/output" \
    --entrypoint /bin/bash "$image" -s -- "$app_id" <<'CONTAINER'
set -euo pipefail

app_id=$1
manifest=/input/$app_id.yml
arch=$(flatpak --default-arch)
work_dir=$(mktemp -d)
cd "$work_dir"
builder=(flatpak-builder --sandbox --disable-rofiles-fuse --arch="$arch")

printf '\n[1/4] Lint the manifest for %s\n' "$arch"
flatpak-builder-lint --exceptions manifest "$manifest"

printf '\n[2/4] Install runtimes, fetch sources, and build the Flatpak for %s\n' "$arch"
"${builder[@]}" --install-deps-from=flathub --install-deps-only --assumeyes app "$manifest"
"${builder[@]}" --download-only app "$manifest"
"${builder[@]}" --disable-download --force-clean --default-branch=stable \
    --override-source-date-epoch=1321009871 --compose-url-policy=full \
    --mirror-screenshots-url=https://dl.flathub.org/media --repo=repo app "$manifest"

printf '\n[3/4] Lint the exported repository\n'
flatpak-builder-lint --exceptions repo repo

printf '\n[4/4] Export the Flatpak bundle\n'
bundle_tmp=$(mktemp "/output/.$app_id-$arch.XXXXXXXX")
trap 'rm -f "$bundle_tmp"' EXIT
flatpak build-bundle --arch="$arch" --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
    repo "$bundle_tmp" "$app_id" stable
chmod 644 "$bundle_tmp"
bundle_name=$app_id-$arch.flatpak
mv -f "$bundle_tmp" "/output/$bundle_name"
printf 'Bundle saved to tools/flathub-release/output/%s\n' "$bundle_name"
CONTAINER
