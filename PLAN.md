# RFW Implementation Plan

This document provides the current implementation plan for Remote Flutter Widgets (RFW). For completed stages 1-10, see [COMPLETED_PLAN.md](COMPLETED_PLAN.md).

---

## Overview

**Goal:** Implement a production-ready RFW architecture that enables server-driven UI while maintaining application stability.

**Current Status:** Stages 1-10 complete, Stage 11 in progress (13 of 15 forms complete), 135 tests passing.

**Reference Architecture:** Three-layer model (DESIGN.md Section 2.1)
- Data Layer: Fetching and caching .rfw binaries
- Domain Layer: DynamicContent transformation
- Presentation Layer: Runtime bridge and RemoteWidget rendering

---

## Stage 11: Advanced Form Widget Composition (IN PROGRESS)

**Objective:** Demonstrate RFW's capability for complex form handling with validation, formatting, and event-driven submission patterns.

### Structure

Forms are organized into 3 demo pages accessible from the main app navigation:

- **Basic Forms Page** (Forms 1-5): Simple inputs with basic validation ✅ COMPLETE
- **Intermediate Forms Page** (Forms 6-10): Multi-component forms with complex validation ✅ COMPLETE
- **Advanced Forms Page** (Forms 11-15): Composite forms with cross-field validation

### Progress

**Basic Forms (1-5)** ✅ COMPLETE
- ✅ Form 1: Simple Text Input
- ✅ Form 2: Email Input with Validation
- ✅ Form 3: Password Input with Visibility Toggle
- ✅ Form 4: Phone Number Input with Formatting
- ✅ Form 5: Numeric Input with Range

**Intermediate Forms (6-10)** ✅ COMPLETE
- ✅ Form 6: Multi-line Text Area with Character Counter
- ✅ Form 7: Searchable Dropdown Select
- ✅ Form 8: Radio Button Group with "Other" Option
- ✅ Form 9: Checkbox Group with Min/Max Selection
- ✅ Form 10: Date Range Picker

**Advanced Forms (11-15)** - IN PROGRESS
- ✅ Form 11: Rating Slider with Labels
- ✅ Form 12: Autocomplete Search Field (multi-select up to 3)
- ✅ Form 13: Address Form (Composite)
- Form 14: Credit Card Form (Composite)
- Form 15: Complete Registration Form (Multi-section)

### Tasks Remaining

#### 11.3. Advanced Forms Page (5 Forms)

**Form 11: Rating Slider with Labels**
- Horizontal slider 1-10 with semantic labels at key points
- Submit Rating button, Skip button
- Validation: Selection required
- Events: `rating_changed`, `form_submit`, `form_skip`

**Form 12: Autocomplete Search Field**
- Suggestion dropdown as user types, debounced query
- Select button, Clear button
- Validation: Must select from suggestions
- Events: `search_typed`, `suggestion_selected`, `form_submit`, `form_clear`

**Form 13: Address Form (Composite)**
- Street, City, State dropdown, ZIP with cross-validation
- Save Address button, Use Different Address button
- Validation: All required, ZIP format, state filters by country
- Events: `field_changed`, `address_complete`, `form_submit`, `form_cancel`, `form_validate`

**Form 14: Credit Card Form (Composite)**
- Card number (type detection), expiry MM/YY, CVV, name
- Pay Now button, Cancel Payment button
- Validation: Luhn algorithm, expiry not past, CVV length by type
- Events: `card_number_changed`, `card_form_valid`, `form_submit`, `form_cancel`

**Form 15: Complete Registration Form**
- Multi-section: Personal Info, Account Setup, Preferences
- Progress indicator, per-section validation, final submission
- Sections:
  1. Personal: First/Last name, DOB, Phone
  2. Account: Email, Password, Confirm Password
  3. Preferences: Newsletter, Contact method, Interests
- Events: `section_changed`, `section_validated`, `form_next_section`, `form_prev_section`, `form_submit`, `form_start_over`

#### 11.4. Create Demo Page

- `lib/features/forms_advanced/presentation/advanced_forms_page.dart`

#### 11.5. Wire Navigation

- Add navigation entry for Advanced Forms page

### Lessons Learned (Stage 11)

- RFW TextField doesn't support controlled value by default - created `_ControlledTextField` wrapper
- Only sync TextField from host when value is cleared (empty string) to avoid cursor/focus issues
- Use `form_submit_denied` event for invalid submissions instead of `form_submit` with `isValid: false`
- Always use `mainAxisSize: "min"` on Column/Row in forms to prevent overflow
- IconButton is not registered in RFW - use InkWell + Icon instead
- Material Icons codepoints are unreliable - use Unicode text characters instead (● ○ for radio, ☑ ☐ for checkbox)
- Container decoration color doesn't render - use ClipRRect + ColoredBox + SizedBox pattern
- RFW doesn't support `==` operator in property values - compute comparison results in host and pass as booleans
- Pass status colors as integers from host rather than using switch expressions on strings
- Multiline TextField: add `maxLines` support to `_ControlledTextField`, use Shift+Enter for newlines
- TextField onChanged events send `{value: "text"}` - handler must read `args['value']`, not custom field names
- Slider widget is not registered in RFW - implement using tappable InkWell buttons in a Row
- RFW DSL doesn't support `null` literals - use empty string `""` with switch statements instead
- For dropdowns without native RFW support, use InkWell + styled Container to mimic TextField appearance, open native Flutter bottom sheet for selection

### Gate 11: Form Widget Verification

| Criteria | Validation Method |
|----------|-------------------|
| All 15 forms render correctly | Visual inspection + widget tests |
| Validation displays error states | Test invalid input scenarios |
| Events fire with correct payloads | Event capture tests |
| Forms work in web build | Test on GitHub Pages |
| Navigation between form pages works | Manual verification |

**Exit Condition:** All 15 form widgets functional with validation and events.

---

## Stage 12: Contract Testing & Versioning Governance

**Objective:** Prevent contract drift between client and server.

**DESIGN.md Reference:** Section 5.1 (Versioning), Section 6.2 (Contract Tests)

### Tasks

12.1. Implement Contract Tests:
- Test missing data handling
- Test null values
- Test empty data
- Test type mismatches

12.2. Create edge-case data generator

12.3. Define version negotiation protocol

12.4. Implement graceful degradation:
- Unknown widget type renders placeholder
- Malformed data shows error state (not crash)

12.5. Set up server-side version routing documentation

### Gate 12: Contract Verification

| Criteria | Validation Method |
|----------|-------------------|
| Missing data shows blank, not crash | Contract tests pass |
| Type mismatch handled gracefully | Contract tests with wrong types |
| Unknown widget renders placeholder | Test with undefined widget reference |
| Version negotiation documented | Spec document review |
| Server compatibility matrix defined | Document review |

**Exit Condition:** System gracefully handles contract violations; version governance documented.

---

## Stage 13: Production Hardening

**Objective:** Address performance, security, and error handling for production deployment.

**DESIGN.md Reference:** Section 7 (Problem Identification)

### Tasks

13.1. Performance optimization:
- Verify binary `.rfw` delivery
- Measure parsing performance
- Optimize DynamicContent transformation

13.2. Address prop drilling (DESIGN.md Section 7.2)

13.3. Implement Circuit Breaker for rendering

13.4. Security hardening:
- Widget tree depth limit
- Rendering timeout
- Response signature validation

13.5. Error monitoring integration

13.6. Performance monitoring

### Gate 13: Production Readiness Verification

| Criteria | Validation Method |
|----------|-------------------|
| All production widgets use binary format | Asset inspection |
| Infinite recursion doesn't crash app | Test with recursive widget |
| Stack overflow caught and handled | Test with deep nesting |
| Error reporting captures RFW failures | Verify in monitoring |
| Performance metrics within targets | Load testing results |
| Security review completed | Security team sign-off |

**Exit Condition:** Production deployment approved; monitoring and error handling operational.

---

## Implementation Summary

| Stage | Objective | Key Deliverable | Status |
|-------|-----------|-----------------|--------|
| 1-10 | Foundation through CI/CD | See COMPLETED_PLAN.md | ✅ |
| 11 | Form Widgets | 15 forms across 3 demo pages | 🔄 13/15 |
| 12 | Contract Testing | Versioning governance | |
| 13 | Hardening | Production readiness | |

---

## Risks and Decisions

### Active Risks

**R-1: High-frequency TextField Events (MEDIUM)**
- Mitigated with debouncing in Stage 6
- Form widgets use controlled text pattern

**R-2: No LocalWidgetLibrary Version Tooling (MEDIUM)**
- Manual review process in place
- Consider custom linter rule

### Decisions Made

1. **State Management:** Riverpod
2. **Server Backend:** Mock server (for spike)
3. **Binary Compilation:** Build-time Dart script
4. **Error UI:** Layered Error Handling (see QUESTIONS.md)
5. **Performance Targets:**
   - Cached widget render: <200ms
   - Network widget load: <3s (P95)
   - Binary parse time: <50ms

---

## Quick Reference

### Common Commands

```bash
flutter pub get              # Install dependencies
flutter test                 # Run all tests
flutter analyze              # Static analysis
dart run tool/compile_rfw.dart  # Compile .rfwtxt -> .rfw

flutter run -d macos         # Run on macOS
flutter run -d chrome        # Run on web
```

### Test Commands

```bash
flutter test                                    # All tests (135)
flutter test test/rfw/inventory/                # Widget inventory
flutter test test/core/network/                 # Network layer
flutter test test/rfw/events/                   # Event system
```

### Key Files

- `COMPLETED_PLAN.md` - Stages 1-10 details
- `DESIGN.md` - Architecture decisions
- `CLAUDE.md` - Development guidance
- `QUESTIONS.md` - Design rationale
