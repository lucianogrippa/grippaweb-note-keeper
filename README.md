
# note_keeper
Note Keeper is an offline app for organizing notes and securely storing sensitive information, such as passwords. Your data stays on your device and is not sent to a server or cloud service. The local database is encrypted, and a master key is generated on first launch and stored using the platform's secure storage.

Organize your notes into categories and groups, and protect access to the app with a local account.


### Supported platforms

Note Keeper is currently configured for Android, Linux, macOS, and Windows. Web deployment is not supported.

### Run from source

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then run:

```bash
flutter pub get
flutter run -d <device-id>
```

To create a release build, use the command for your target platform:

```bash
flutter build apk
flutter build linux
flutter build macos
flutter build windows
```

If a prebuilt release is available, download it from the project's [Releases](https://github.com/lucianogrippa/grippaweb-note-keeper/releases) page.
