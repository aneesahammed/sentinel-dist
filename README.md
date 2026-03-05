# Sentinel (Quick Guide)

Sentinel is a local-first error triage tool for development logs.  
It ingests logs from your app/tests, groups recurring failures into issues (fingerprints), stores history in SQLite, and provides a local UI for triage.

Sentinel is distributed as a **single binary file** (no Docker, no sidecar, no extra runtime required for offline usage).

Primary use: run your app or tests via `sentinel run -- <command>` to capture logs/errors and quickly investigate recurring issues.

Release page: [https://github.com/aneesahammed/sentinel-dist/releases](https://github.com/aneesahammed/sentinel-dist/releases)

## 1) Download the right binary

From the latest release, download the asset matching your OS/CPU:

| OS | CPU | Asset name pattern |
|---|---|---|
| macOS (Apple Silicon) | arm64 | `sentinel_<version>_darwin_arm64` |
| macOS (Intel) | amd64 | `sentinel_<version>_darwin_amd64` |
| Linux | amd64 | `sentinel_<version>_linux_amd64` |
| Windows | amd64 | `sentinel_<version>_windows_amd64.exe` |

`<version>` looks like `0.1.0+6`.

## 2) Put Sentinel on PATH (recommended)

### macOS / Linux

```bash
mkdir -p ~/bin
# Move your downloaded file to ~/bin and rename it to sentinel
mv ~/Downloads/<downloaded-file> ~/bin/sentinel
chmod +x ~/bin/sentinel

# zsh (default on modern macOS)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\bin" | Out-Null
# Move your downloaded file and rename it to sentinel.exe
Move-Item "$env:USERPROFILE\Downloads\<downloaded-file>.exe" "$env:USERPROFILE\bin\sentinel.exe"

# Add ~/bin-equivalent to user PATH (new terminal required)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\bin", "User")
```

If Windows SmartScreen appears, click **More info** -> **Run anyway** once.
If macOS blocks first launch, allow it in **System Settings -> Privacy & Security**.

## 3) Verify install

```bash
sentinel --help
sentinel check --offline
```

## 4) Capture logs/errors from your app

Recommended flow:

```bash
sentinel run --offline -- <your command>
```

Examples:

```bash
sentinel run --offline -- npm run dev
sentinel run --offline -- python app.py
```

Why `run` mode: it captures **both stdout and stderr** and starts local trace ingestion automatically (if your app is OTel-instrumented).

## 5) OpenTelemetry note (quick)

- `sentinel run -- ...` is the easiest path: Sentinel auto-configures OTLP exporter vars for the child process.
- For `sentinel stdin` / `sentinel watch`, you must configure OTEL manually and include the printed `sentinel.session_id` in `OTEL_RESOURCE_ATTRIBUTES`.

Minimal manual OTEL example (`stdin/watch`):

```bash
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
export OTEL_RESOURCE_ATTRIBUTES="service.name=my-service,sentinel.session_id=<session>,sentinel.project=default"
```

## 6) Open the UI

```bash
sentinel ui
```

Then open `http://127.0.0.1:4040` (or use `--port` if needed).

![Sentinel UI](https://github.com/user-attachments/assets/2756d744-b0db-4beb-a6a6-07514e244a10)

## 7) Optional: update later

```bash
sentinel update
```
