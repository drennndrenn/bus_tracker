# Smart Bus Tracker Mobile (Flutter)

This folder contains the Flutter mobile app conversion scaffold for the existing Smart Bus Tracker web UI.

## Run locally

1. Install Flutter SDK.
2. From this folder:

```bash
flutter pub get
flutter run
```

## Organized structure

The project uses a feature-first structure so it stays easy to navigate:

- `lib/core`: theme, shared constants, app-level styles.
- `lib/features`: each product area (`home`, `routes`, `alerts`, `about`, `contact`) with its own pages/widgets/models.
- `lib/shared`: reusable widgets used by multiple features.

## Notes

- The current scaffold mirrors the original tabs and baseline layout.
- Next step is 1:1 visual parity with every card, modal, and map interaction from the web app.
