Configuring this Android beacon library has grown into a mixed bag over the years: some options live in manifest declarations, some are static fields on `BeaconManager`, some are instance methods, others hang off `Beacon` or the parsers. Worse, changing any of them after ranging or monitoring has already started is unpredictable — it is poorly documented which changes take effect immediately, some quietly do nothing until the next scan cycle, and a few can crash. We want a single, coherent configuration surface that library users can reason about, that works cleanly from both Kotlin and Java, and that applies a group of changes as one transaction so behavior is deterministic. This is the new configuration API targeted for 3.0; it should live in package `org.altbeacon.beacon` alongside the existing settings for now.

## The Settings type

Please introduce a `Settings` type whose every field is optional and unset by default, so an instance describes only a *delta* of what the caller wants to change. From Kotlin a caller must be able to configure only the subset of fields they want in a single expression, as in `Settings(debug = true, regionExitPeriodMillis = 45000)`.

A field the caller did not mention is absent rather than set to anything, and reading it back off that `Settings` instance gives null. That makes the defaults below a property of the library rather than of any particular `Settings`.

It must expose these configurable fields, matching the names and types below exactly:

| Field | Type | Library default |
|---|---|---|
| `debug` | `Boolean` | `false`. True switches the library log level to debug, false to info |
| `distanceModelUpdateUrl` | `String` | the empty string, meaning disabled |
| `scanPeriods` | `Settings.ScanPeriods` | `ScanPeriods()`, described below |
| `scanStrategy` | `Settings.ScanStrategy` | `JobServiceScanStrategy()` on Android 8 and above, `BackgroundServiceScanStrategy()` below it |
| `longScanForcingEnabled` | `Boolean` | `false` |
| `distanceCalculatorFactory` | `DistanceCalculatorFactory` | a factory whose calculator reproduces the distance the library already computes today |
| `regionStatePersistenceEnabled` | `Boolean` | `true` |
| `hardwareEqualityEnforced` | `Boolean` | `false` |
| `regionExitPeriodMillis` | `Int` | `30000` |
| `useTrackingCache` | `Boolean` | `true` |
| `maxTrackingAgeMillis` | `Int` | `10000` |
| `manifestCheckingDisabled` | `Boolean` | `false` |
| `beaconSimulator` | `BeaconSimulator` | a simulator that supplies no beacons, so nothing is simulated unless a caller asks for it |
| `rssiFilterImplClass` | `Class<RunningAverageRssiFilter>` | the running-average rssi filter the library already falls back to today |

Scan periods are described by a nested `Settings.ScanPeriods` value. Its four periods are counts of whole milliseconds held as `Long`, and it is constructed positionally as `ScanPeriods(foregroundScanPeriodMillis, foregroundBetweenScanPeriodMillis, backgroundScanPeriodMillis, backgroundBetweenScanPeriodMillis)` and also usable via those named parameters. Its defaults are foreground 1100, foreground-between 0, background 30000, background-between 0, so a bare `ScanPeriods()` carries exactly those four.

Because Java callers cannot use Kotlin named or default arguments, also provide a fluent `Settings.Builder`, so that `new Settings.Builder().setDebug(true).setScanPeriods(periods).build()` reads naturally from Java. These five setters have to be there: `setDebug(boolean)`, `setDistanceModelUpdateUrl(String)`, `setScanPeriods(ScanPeriods)`, `setScanStrategy(ScanStrategy)` and `setLongScanForcingEnabled(boolean)`. Covering more of the fields above is fine, so treat those five as the floor rather than the whole list.

Each setter hands back the same builder instance so calls chain, and `build()` yields a `Settings` carrying only the fields that were actually set, every other field still absent. Expose the library defaults through `Settings.Defaults`, holding a default for each field in the table and readable without instantiating anything, for example `Defaults.distanceModelUpdateUrl`. How you shape that holder is up to you.

## Scan strategies and the distance calculator

The scan strategy replaces the old scattered scheduling flags with a small set of `Settings.ScanStrategy` implementations, one per scanning mode the library supports:

- `Settings.ForegroundServiceScanStrategy(notification, notificationId)`, taking an Android `Notification` and an int id
- `Settings.JobServiceScanStrategy(immediateJobId, periodicJobId, jobPersistenceEnabled)`, which is the default strategy on Android 8+
- `Settings.BackgroundServiceScanStrategy()`
- `Settings.IntentScanStrategy()`

They can be compared for equality so the library can detect an actual strategy change. Two strategies of different kinds never compare equal. Two of the same kind compare equal when the values they were built from match, and for the foreground strategy the notification counts as one of those values by identity, so two foreground strategies built from separate notification objects are not equal even when those notifications were configured the same way.

Alongside this, add a `DistanceCalculatorFactory` interface with a single method `getInstance(context: Context): DistanceCalculator`, sitting beside the `DistanceCalculator` it returns rather than with the rest of this API. Let callers supply their own factory through the `distanceCalculatorFactory` field, and ship a default factory that is used when the caller supplies none. When no factory is supplied, that default one has to preserve the distance calculation the library already performs today.

## Applying settings

Wire three application methods onto `BeaconManager`:

- `adjustSettings(settings)` applies only the fields explicitly set on the passed `Settings`, leaving everything else at its current value, which is a delta merge
- `replaceSettings(settings)` applies the set fields and resets every unset field to the library default
- `revertSettings()` returns all settings to their defaults

Applying settings happens as one transaction, so the whole delta is resolved against the current values before anything is written. `adjustSettings` merges against whatever is in force at the moment of the call, `replaceSettings` fills every unset field from the defaults, and a later call sees the result of the earlier one rather than a mixture. A scan strategy can change while consumers are already bound. Any consumer that was bound before such a call has to end up bound again and connected afresh to the new scanning mode, so that it receives the service connection callback a second time, and the mode it started under has to be shut down rather than left running alongside the new one. Unless releasing the old mode has to wait on something, that is all complete when the call returns.

Reading back the applied configuration is done through `beaconManager.getActiveSettings()` (`beaconManager.activeSettings` from Kotlin), which returns a resolved snapshot of what is currently in force. Once one of the three calls above returns, every field on it is filled in, either from the value just applied, the value already in force, or the library default.

That snapshot is not a `Settings`, and the difference matters. A `Settings` describes a delta, so every field on it is optional and reads back as null when the caller never mentioned it. The snapshot describes a whole configuration, so it is its own type carrying the same fields under the same names as the table above. Reading a field off it hands back a resolved value the caller can use straight away rather than an optional to unwrap first. The rssi filter class is the one field there that may stay optional, and the rest are not. What you call that type is up to you.

Snapshots are independent of the live configuration in both directions: a later change to the live configuration does not alter a snapshot already handed out, and reshaping a snapshot does not reach the live configuration. A snapshot supports `copy(...)`, naming just the fields to change, and what comes back is another snapshot rather than anything the library has been told about.

Every field is also written through to the configuration the library already keeps, so the applied value is readable back from the property that already owns it: the log level for `debug`, the distance model update url, the four scan periods, the region exit period, region state persistence and manifest checking on `BeaconManager`, hardware equality on `Beacon`, the tracking cache and the maximum tracking age on the ranging classes that hold them, the rssi filter class on `BeaconManager`, a configured beacon simulator on `BeaconManager` (with the default simulator in force nothing is simulated and the manager holds no simulator at all), and the active distance calculator as an instance produced by whichever factory is in force.

Long scan forcing is the one field with no reader on `BeaconManager` today, so give it a static `getLongScanForcingEnabled()` alongside the others and have the scanning code consult it, so that a scanning service started after the setting is applied is running with long scan forcing switched on.

A scan strategy has to take effect rather than merely be recorded, so applying one puts the library into the scheduling mode that strategy describes, using the values it was constructed with. For the job service strategy that means the job ids and the persistence flag it was given are the ones the library records for its scheduling and reads back through `ScanJob`. `ScanJob` already exposes the ids; the persistence flag needs a `getJobPersistenceEnabled()` of its own.

Two constraints to keep in mind. This is an addition to the library rather than a replacement, so the static configuration methods this API manages have to still be there and still work when a caller reaches for them directly. Where the two surfaces overlap the new API is the one that wins, because applying settings writes every field it manages onto that older configuration, so a value a caller had set directly through a static setter beforehand is replaced by the resolved value rather than preserved. Putting the default distance calculator in place is part of applying settings, so a caller that never applies any settings does not get one installed on its behalf.
