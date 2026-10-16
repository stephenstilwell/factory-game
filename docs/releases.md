# Windows builds and GitHub releases

The build uses the Godot version in [.godot-version](../.godot-version), the Windows Desktop preset in [export_presets.cfg](../export_presets.cfg), and official editor/templates verified against the release's SHA-512 checksums.

## Local package

From the project folder in Windows PowerShell:

```powershell
./tools/install-godot.ps1
$version = (Get-Content .godot-version -Raw).Trim()
$godot = Join-Path $env:TEMP "factory-game-godot/$version/Godot_v$version-stable_win64_console.exe"
./tools/build-windows.ps1 -Godot $godot -Version 0.1.0-dev
```

The installer downloads the official template archive (about 1.3 GB on the first run), installs only Windows templates and graphics libraries, and reuses the installation. Editor/download files stay in the system temporary directory; templates live in Godot's normal application-data directory.

The build imports resources, runs integration checks, exports a release executable and separate game pack, launches the exported executable headlessly, and creates a ZIP with player instructions and source/version metadata. Any detected Godot errors fail the build. Logs and SHA-256 checksums accompany the ZIP under the ignored `exports/<version>/` directory. Use a new version or move the previous staging folder before repeating a build of the same version.

Extract the ZIP and run `Ironworks.exe` for a graphical play check before publishing. Verify fullscreen/windowed switching, the empty-world tutorial, mining/crafting, and saving/loading. Headless startup checks do not verify graphics drivers or every gameplay interaction. Builds are unsigned; code signing can be added later.

## GitHub workflow

Every push to `main` builds and checks Windows automatically. You can also use **Actions -> Windows build and release -> Run workflow** for a package without creating a release. Successful runs retain a `windows-release` artifact for 14 days. Download and extract that artifact to find the playable ZIP and its checksum.

To prepare a release, commit and push the intended changes, then create a version tag:

```powershell
git tag -a v0.2.0 -m "Ironworks 0.2.0"
git push origin v0.2.0
```

A successful tag build creates a **draft prerelease**, with the playable ZIP and SHA-256 checksum attached. The workflow uses `docs/release-notes/<version>.md` when present, otherwise GitHub generates notes. Review the draft under **Releases**, test its download, and click **Publish release** when ready. Ordinary main-branch pushes and manual runs do not publish releases.

No personal access token or extra repository secrets are needed: GitHub Actions uses its scoped `GITHUB_TOKEN`. The build job can read repository contents; only the draft-release job can write them. Keep `.godot/export_credentials.cfg` untracked if signing or encrypted exports are added.

The repository is currently private. A published release is still restricted to people with repository access. Public distribution requires a separate decision about repository visibility or another distribution channel.

Official references: [Godot command-line exports](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html), [GitHub releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).