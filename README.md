# RFW Spike

Remote Flutter Widgets (RFW) implementation spike. Server-driven UI architecture enabling OTA widget updates.

## Current Status

**Completed Stages:** 1-8 of 11
**Tests:** 114 passing

| Stage | Description | Status |
|-------|-------------|--------|
| 1 | Project Foundation | ✅ |
| 2 | Core Registry | ✅ |
| 3 | Static Rendering | ✅ |
| 4 | Golden Tests | ✅ |
| 5 | Dynamic Data Binding | ✅ |
| 6 | Event System | ✅ |
| 7 | Network Layer | ✅ |
| 8 | Widget Inventory | ✅ |
| 9 | Extended Widget Library | Pending |
| 10 | Contract Testing | Pending |
| 11 | Production Hardening | Pending |

## Quick Start

```bash
# Install dependencies
flutter pub get

# Compile RFW widgets (source -> binary)
dart run tool/compile_rfw.dart

# Run the app
flutter run

# Run all tests
flutter test
```

## Architecture

```
lib/
├── core/
│   ├── rfw/
│   │   ├── registry/      # Widget registries (core, material)
│   │   └── runtime/       # Runtime, ActionHandler, Debouncer
│   └── network/           # RfwRepository, RfwCacheManager
├── features/
│   ├── remote_view/       # RemoteView, SafeRemoteView, NetworkRemoteView
│   ├── demo/              # Stage 5 demo (data binding)
│   ├── events/            # Stage 6 demo (event system)
│   └── network/           # Stage 7 demo (network & caching)
assets/rfw/
├── source/                # .rfwtxt source files
└── defaults/              # Compiled .rfw binaries
```

## Running Tests

```bash
# All tests
flutter test

# By category
flutter test test/rfw/                    # All RFW tests
flutter test test/rfw/events/             # Event system (32 tests)
flutter test test/rfw/goldens/            # Golden/visual tests
flutter test test/core/network/           # Network layer (30 tests)
```

### Test Groups

| Group | File | Tests | Description |
|-------|------|-------|-------------|
| **Widget Inventory** | `rfw/inventory/widget_inventory_test.dart` | 17 | ProductCard, Feed items, MetricCard, OfferBanner |
| **RfwCacheManager** | `core/network/rfw_cache_manager_test.dart` | 12 | Cache entry, TTL, eviction |
| **RfwRepository** | `core/network/rfw_repository_test.dart` | 18 | Network fetch, fallback chain, headers |
| **ActionHandler** | `rfw/events/action_handler_test.dart` | 14 | Handler registration, event dispatch, error handling |
| **Debouncer** | `rfw/events/debouncer_test.dart` | 12 | Debounce/throttle for high-frequency events |
| **Event Integration** | `rfw/events/event_integration_test.dart` | 6 | Button events, toggle round-trip, event loop |
| **Data Binding** | `rfw/data_binding_test.dart` | 10 | InfoCard, StatusBadge, transformers |
| **Golden Tests** | `rfw/goldens/*.dart` | 4 | Visual regression tests |
| **Registry** | `rfw/registry_test.dart` | 6 | Core/material widget registration |
| **Remote View** | `rfw/remote_view_test.dart` | 4 | Widget rendering, error handling |
| **RFW Environment** | `rfw/rfw_environment_test.dart` | 6 | Runtime initialization |

## Key Files

### Widget Inventory (Stage 8)
- `lib/features/inventory/presentation/inventory_demo_page.dart` - Demo page
- `test/rfw/inventory/widget_inventory_test.dart` - Widget tests (17 tests)

**Widgets Created:**
| Widget | Example | Features | Events |
|--------|---------|----------|--------|
| ProductCard | 8 | Image placeholder, title/subtitle, price, action button | product_action |
| FeedItemPost | 9 | Author avatar, content, timestamp, like/comment/share | post_like, post_comment, post_share |
| FeedItemAd | 9 | Sponsored label, headline, description, CTA button | ad_click |
| FeedItemPromo | 9 | Solid color background, promo code, claim button | promo_claim |
| MetricCard | 10 | Icon, value, label, trend indicator (up/down/neutral) | - |
| OfferBanner | 10 | Title, description, claim button | offer_claim |

### Network Layer (Stage 7)
- `lib/core/network/rfw_cache_manager.dart` - File-based cache with TTL, atomic writes
- `lib/core/network/rfw_repository.dart` - Network fetch with fallback chain
- `lib/features/remote_view/network_remote_view.dart` - Network-aware RemoteView
- `lib/features/network/presentation/network_demo_page.dart` - Demo page

**Features:**
- Fallback chain: Cache → Network → Bundled Assets
- HTTP headers: X-Client-Version, X-Client-Widget-Version (capability handshake)
- Conditional requests: ETag/If-None-Match support
- Response handling: 200, 304, 404, 426 status codes
- Atomic writes: Temp file + rename pattern
- LRU eviction when cache exceeds max size

### Event System (Stage 6)
- `lib/core/rfw/runtime/action_handler.dart` - Event handler infrastructure
- `lib/core/rfw/runtime/debouncer.dart` - Debounce/throttle utilities
- `assets/rfw/source/action_button.rfwtxt` - Button with events
- `assets/rfw/source/feature_toggle.rfwtxt` - Toggle (stateless round-trip)
- `assets/rfw/source/email_input.rfwtxt` - Text input (high-frequency)

### Data Binding (Stage 5)
- `lib/features/demo/data/transformers.dart` - Domain -> DynamicContent
- `lib/features/demo/data/providers.dart` - Riverpod state

### Core
- `lib/core/rfw/runtime/rfw_environment.dart` - Runtime singleton
- `lib/core/rfw/registry/core_registry.dart` - Core widget wrappers
- `lib/core/rfw/registry/material_registry.dart` - Material widget wrappers

## RFW Widget Compilation

Source `.rfwtxt` files are compiled to binary `.rfw` for production:

```bash
dart run tool/compile_rfw.dart
```

Output:
```
Compiling: assets/rfw/source/action_button.rfwtxt
  -> assets/rfw/defaults/action_button.rfw
     Source: 1064 bytes, Binary: 1104 bytes
```

## Documentation

- `PLAN.md` - Implementation plan with gate criteria
- `DESIGN.md` - Architecture and RFW patterns
- `QUESTIONS.md` - Design decisions and rationale
