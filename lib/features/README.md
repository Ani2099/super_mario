# Features Directory

This directory contains modular features of the game, structured according to Clean Architecture principles.
Each feature should ideally be split into three layers:
1. **Domain**: Models, entities, and use cases defining the business logic.
2. **Data**: Data sources, repositories, and API clients implementing data retrieval and local saving.
3. **Presentation**: Flutter UI widgets, Flame overlays, state providers, and controllers.

## Planned Features
- `menu`: Main menu and navigation overlays.
- `settings`: Game settings management (audio levels, custom controls).
- `game`: Flame integration, gameplay loop, camera controllers.
- `shop`: Skin purchases, currency exchange, bundles.
- `achievements`: Unlocks, stats tracking, progression.
- `save`: Save slots, encryption, sync handlers.
