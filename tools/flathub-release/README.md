# Check the Flathub package locally

Prepare the generated manifest following the release wiki, then run the
verification from the root of this checkout. [Release wiki, Post-1](https://github.com/FriesI23/mhabit/wiki/Dev%EA%9E%89-Push-To-New-Version#post-1-update-flathub-manifest)

```bash
./tools/flathub-release/check.sh
```

Use Bash and Docker with Linux containers. On macOS, start Docker Desktop
before running the script. It builds for the Docker daemon's native
architecture, typically `aarch64` on Apple Silicon and `x86_64` on Intel Macs.
The container uses privileged mode for Flatpak's build sandbox.

1. Lint the generated manifest in the current checkout.
2. Install the build runtimes, download the pinned sources, and build the
   Flatpak in the sandbox with source downloads disabled.
3. Lint the exported Flatpak repository.
4. Write `io.github.friesi23.mhabit-<arch>.flatpak` to
   `tools/flathub-release/output/`.

The checkout is mounted read-only and build state is kept in the container.
