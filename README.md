# RFW Spike

[![CI](https://github.com/runyaga/rfw_demo/actions/workflows/ci.yml/badge.svg)](https://github.com/runyaga/rfw_demo/actions/workflows/ci.yml)
[![Deploy](https://github.com/runyaga/rfw_demo/actions/workflows/deploy.yml/badge.svg)](https://github.com/runyaga/rfw_demo/actions/workflows/deploy.yml)

**[Live Demo](https://runyaga.github.io/rfw_demo/)**

Remote Flutter Widgets (RFW) implementation spike. Server-driven UI architecture enabling OTA widget updates.

## Status

**Stages:** 9 of 12 complete | **Tests:** 135 passing

| Stage | Description | Status |
|-------|-------------|--------|
| 1-8 | Foundation through Widget Inventory | ✅ |
| 9 | Extended Widget Library | ✅ |
| 10 | CI/CD & GitHub Pages | In Progress |
| 11 | Contract Testing | Pending |
| 12 | Production Hardening | Pending |

## Quick Start

```bash
flutter pub get
dart run tool/compile_rfw.dart   # Compile .rfwtxt -> .rfw
flutter run -d macos             # or chrome
flutter test
```

## Architecture

```
lib/
├── core/
│   ├── rfw/
│   │   ├── registry/      # core, material, map widgets
│   │   └── runtime/       # RfwEnvironment, ActionHandler, Debouncer
│   └── network/           # RfwRepository, RfwCacheManager
├── features/
│   ├── remote_view/       # RemoteView, SafeRemoteView, NetworkRemoteView
│   ├── demo/              # Data binding demo
│   ├── events/            # Event system demo
│   ├── network/           # Network & caching demo
│   ├── inventory/         # Widget inventory demo
│   └── widgets_extended/  # Stage 9: Extended widgets demo
assets/rfw/
├── source/                # .rfwtxt source files
└── defaults/              # Compiled .rfw binaries
```

## Widgets

| Widget | Stage | Description |
|--------|-------|-------------|
| hello_world | 3 | Basic text rendering |
| info_card | 5 | Card with title, description, icon |
| status_badge | 5 | Colored badge with status text |
| user_list | 5 | List of user items |
| action_button | 6 | Button with event firing |
| feature_toggle | 6 | Switch with stateless round-trip |
| email_input | 6 | TextField with validation |
| product_card | 8 | Image, title, price, action button |
| feed_item_post | 8 | Social post with like/comment/share |
| feed_item_ad | 8 | Sponsored ad with CTA |
| feed_item_promo | 8 | Promo banner with claim button |
| metric_card | 8 | KPI with trend indicator |
| offer_banner | 8 | Promotional offer with CTA |
| accordion | 9 | ExpansionTile, collapsible sections |
| tabbed_content | 9 | Tab switching, content areas |
| breadcrumbs | 9 | Navigation path, click events |
| skeleton_loader | 9 | Loading placeholders (card, list, profile) |
| dropdown_selector | 9 | Selection from options list |
| bottom_nav | 9 | 3-5 item navigation bar |
| datetime_picker | 9 | Date/time with native dialogs |
| map_viewer | 9 | OpenStreetMap with markers, tap events |

## Tests

```bash
flutter test                           # All (135)
flutter test test/rfw/stage9/          # Stage 9 widgets (22)
flutter test test/rfw/inventory/       # Widget inventory (17)
flutter test test/core/network/        # Network layer (30)
flutter test test/rfw/events/          # Event system (32)
```

## Docs

- `PLAN.md` - Implementation stages with gate criteria
- `DESIGN.md` - Architecture and RFW patterns
- `CLAUDE.md` - AI assistant guidance
