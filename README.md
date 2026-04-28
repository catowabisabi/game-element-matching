# Elementary

Elementary is a gesture-first Flutter puzzle game based on the original
`element_fusion.html` prototype.

## Core Game

- Swipe the 4x4 board to move elements.
- Fire, water, and earth evolve through fusion.
- Cross-element reactions create plant, lava, steam, stone obstacles, and the
  philosopher's stone.
- Long press the board to spend coins on a direction hint.
- Double tap the board to use mana and clear a blocker or low-level tile.
- Swipe up from the main game to visit the pet layer, then swipe down to return.

## Development Notes

This repository is now the `elementary` Flutter game. The source HTML prototype
is kept in `docs/reference/`.

When Flutter is available on the machine:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```
