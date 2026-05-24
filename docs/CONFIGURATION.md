# TOML Configuration

Snapzy can export and import user-editable TOML configuration for backup,
dotfiles, and machine-to-machine setup.

Suggested path:

```text
~/.config/snapzy/config.toml
```

Snapzy does not silently watch or overwrite this file. Export and import are
explicit actions from Settings -> Advanced, so macOS sandbox file access is
always user-confirmed through the save/open panels.

## Scope

The TOML file covers portable app preferences:

- General settings: language, appearance, sounds, login item, export folder path.
- Capture settings: naming templates, screenshot format, cursor/app inclusion,
  scrolling hints, OCR notification, object cutout auto-crop.
- After-capture actions for screenshot and recording.
- Recording settings: format, quality, FPS, audio, microphone device id, cursor,
  click highlights, keystroke overlay, live annotation shortcuts.
- Quick Access: visibility, position, countdown behavior, action order,
  enabled actions, card slots.
- History: retention, maximum count, floating panel layout and filter.
- Cloud metadata: provider, bucket, region, endpoint, custom domain, expiration,
  and upload window position.
- Annotate preferences.
- Global, overlay, Annotate tool, and Annotate action shortcuts.

The export intentionally excludes secrets and machine-private state:

- Cloud access key and secret key are not exported. They remain in Keychain.
- Cloud credential archive transfer stays in the existing encrypted cloud
  import/export flow.
- Cloud configured/password-protection state is not exported because it depends
  on local Keychain items.
- Capture history, temp files, annotation sidecars, upload history, caches, and
  app diagnostics are not part of `config.toml`.
- File-access security-scoped bookmarks are not portable. Imported folder paths
  may still need to be confirmed in Settings on the destination Mac.

## Schema

Current schema version:

```toml
schema_version = 1
snapzy_min_version = "1.20.0"
```

Unknown keys are ignored. Known keys are validated by type and allowed value.
If import finds any error, Snapzy applies none of the changes. Warnings do not
block import.

## Example

```toml
schema_version = 1
snapzy_min_version = "1.20.0"

[general]
language = "system"
appearance = "system"
play_sounds = true
start_at_login = false
export_location = "~/Desktop"

[capture]
hide_desktop_icons = false
hide_desktop_widgets = false

[capture.naming]
screenshot_template = "Screenshot {yyyy}-{MM}-{dd} at {HH}.{mm}.{ss}"
recording_template = "Recording {yyyy}-{MM}-{dd} at {HH}.{mm}.{ss}"

[capture.screenshot]
format = "png"
include_snapzy = false
show_cursor = false

[capture.after.screenshot]
save = true
quick_access = true
copy_file = false
open_annotate = false
upload_to_cloud = false

[recording]
format = "mov"
quality = "high"
fps = 30
capture_system_audio = false
capture_microphone = false
show_cursor = true
highlight_clicks = false
show_keystrokes = false

[quick_access]
enabled = true
position = "topTrailing"
auto_dismiss = true
auto_dismiss_delay = 8.0
actions_order = ["copy", "saveOrOpen", "edit", "uploadToCloud", "pinToScreen", "dismiss", "delete"]
enabled_actions = ["copy", "delete", "dismiss", "edit", "pinToScreen", "saveOrOpen", "uploadToCloud"]

[history]
enabled = true
retention_days = 30
max_count = 500

[shortcuts.global.fullscreen]
key = "3"
modifiers = ["command", "shift"]
enabled = true
```

## Implementation Notes

- `SnapzyConfigurationService` is the facade used by Settings.
- `SnapzyConfigurationExporter` and its shortcut extension build deterministic
  TOML so exported files are diff-friendly.
- `SnapzyConfigurationImporter` parses, validates, then applies mutations only
  after validation succeeds.
- `SimpleTOMLParser` is intentionally focused on Snapzy's schema surface:
  strings, booleans, integers, doubles, arrays, dotted keys, and nested tables.
