# Architecture

Omarchy Stats is an Omarchy bar widget and system-monitoring panel built with
Quickshell/Qt. It collects system metrics through documented Linux kernel
interfaces and presents them through a native QML interface.

## Design goals

- Keep the always-visible bar path cheap and predictable.
- Start expensive data collection only while a details panel is visible.
- Isolate hardware-specific failures so one missing metric cannot break the UI.
- Keep QML responsible for presentation and interaction, not parsing procfs.
- Use a small versioned JSON-Lines boundary between QML and Python.
- Avoid shell pipelines, terminal windows, privileged helpers, and persistent
  background daemons.

## Runtime paths

### Summary path

Each visible bar widget owns a `src/collector.py --summary` process. It reads only
`/proc/stat`, `/proc/meminfo`, and `/proc/net/dev`, then emits one compact JSON
object per configured interval. It does not enumerate processes, mounts,
sensors, or GPUs.

A bar exists per monitor in Omarchy, so a multi-monitor session may have one
small summary process per visible bar. This intentionally avoids cross-screen
popup ownership and shared mutable QML state; each process performs only three
small procfs reads per interval.

### Detail path

A panel owns a separate `src/collector.py --interval ...` process whose `running`
state is bound to panel visibility. Closing the panel terminates that process.
The detail engine composes independent providers for CPU, memory, storage,
network, GPU, and processes.

Providers return `null` for unsupported values and contain their own
best-effort fallbacks. The snapshot composer prevents one provider failure from
invalidating unrelated sections.

## Project layout

- `src/BarWidget.qml` and `src/collector.py`: small runtime entry points required by the plugin.
- `src/ui/`: panel, tabs, reusable QML components, and display helpers.
- `src/omarchy_stats/`: command handling and Linux metric collection.
- `tests/`: collector behavior and safety checks.
- `assets/`: README and marketplace screenshots.

Within the collector, `summary.py` handles the inexpensive bar sample,
`snapshot.py` combines the detailed providers, and each hardware or system
subsystem has one focused module. QML only presents the resulting data and
handles user interaction.

The JSON payload carries `schema: 1`. Unknown or malformed snapshots are
rejected without replacing the last valid view.

## Process controls

Process actions are intentionally separate one-shot collector invocations.
The collector accepts only `TERM`, `STOP`, `CONT`, and `KILL`, rejects PID 1,
rejects its own process/parent, and rejects processes owned by another user.
The UI confirms every action and requires a second confirmation for `KILL`.

## Failure model

- Missing files and transient `/proc` races become unavailable values.
- procfs and sysfs reads have a hard byte limit; oversized values become unavailable,
  while process command lines are safely truncated.
- The collector caps each JSON line before writing it, and QML rejects oversized
  values before parsing them.
- Optional GPU tools are never required for plugin startup.
- Invalid collector output is surfaced as a panel status message.
- A failed process action reports an error and does not terminate the panel.
- No component launches a terminal, browser, GTK/Electron application, or
  external system-monitor UI.
