# RFW Implementation - Open Questions

This document elaborates on key architectural and organizational decisions required before proceeding with the RFW implementation outlined in PLAN.md.

---

## Table of Contents

1. [Server Backend](#question-2-server-backend)
2. [Binary Compilation Pipeline](#question-3-binary-compilation-pipeline)
3. [Error UI Design](#question-4-error-ui-design)
4. [Performance Targets](#question-5-performance-targets)
5. [Security Review](#question-6-security-review)
6. [Decision Summary](#decision-summary)

---

## Question 2: Server Backend

**Who builds/provides the server component?**

### Why This Matters

DESIGN.md describes a client-server architecture where the server:
- Hosts `.rfw` binary files
- Performs capability handshake (receives client version, serves compatible widgets)
- Potentially compiles `.rfwtxt` → `.rfw` binaries
- Manages widget versioning and A/B testing

Without a server, you can only achieve "offline-first" (Stage 3) - bundled widgets with no over-the-air updates.

### Options

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. Static File Hosting** | S3/GCS bucket with `.rfw` files | Simple, cheap, fast CDN delivery | No version negotiation, no A/B testing, manual file management |
| **B. Simple API Server** | REST endpoint that serves `.rfw` based on version header | Version negotiation possible, moderate complexity | Custom development required, need to maintain |
| **C. Full CMS/SDUI Platform** | Purpose-built system with widget editor, versioning, targeting | Complete solution, non-dev can update UI | Significant investment, build vs buy decision |
| **D. Existing Backend Team** | Another team owns the server component | Separation of concerns, specialists handle it | Coordination overhead, dependency on other team |
| **E. Mock Server (Spike Only)** | Local mock for development/testing | Unblocks client development | Not production-viable |

### Key Decisions

1. **For this spike:** Option E (mock server) is sufficient through Stage 7
2. **For production:** Need to choose A-D based on:
   - Do you need A/B testing? → Requires B, C, or D
   - Do you need version negotiation? → Requires B, C, or D
   - Do non-developers need to update widgets? → Requires C
   - What's your infrastructure team capacity?

### Server Requirements Specification

If another team builds the server, they need this spec:

```
Endpoint: GET /widgets/{widget_id}.rfw

Request Headers:
  X-Client-Widget-Version: "1.2.0"
  X-Platform: "ios" | "android" | "web"
  X-App-Version: "2.5.1"

Response (200):
  Content-Type: application/octet-stream
  Body: Binary .rfw data

Response (406 Not Acceptable):
  When client version too old for requested widget
  Body: { "minimum_version": "1.3.0", "update_url": "..." }

Response (404):
  Widget not found

Caching Headers:
  Cache-Control, ETag for client-side caching
```

### Recommendation

| Context | Recommendation |
|---------|----------------|
| Spike/Prototype | Mock server (Option E) |
| Production | API server with versioning (Option B) |

---

## Question 3: Binary Compilation Pipeline

**Build-time script or CI/CD step?**

### Why This Matters

DESIGN.md Section 7.1 states:
> "Parsing text format (.rfwtxt) on the device is approximately 10x slower than parsing binary (.rfw)"

You **must** compile `.rfwtxt` → `.rfw` before delivery. The question is *when* and *where*.

### Options

| Option | When | Where | Use Case |
|--------|------|-------|----------|
| **A. Local Build Script** | `flutter build` | Developer machine | Bundled assets only |
| **B. CI/CD Pipeline** | PR merge / release | CI server | Bundled assets, consistent builds |
| **C. Server-Side (On Upload)** | Widget author uploads `.rfwtxt` | Backend server | OTA widgets, non-dev authors |
| **D. Server-Side (On Request)** | Client requests widget | Backend server | Dynamic generation (rare) |

### Recommended Approach: Hybrid B + C

```
┌─────────────────────────────────────────────────────────────┐
│                    COMPILATION PIPELINE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  BUNDLED ASSETS (fallbacks):                                │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │ .rfwtxt  │───>│ CI Build │───>│  .rfw    │──> App Bundle│
│  │ (git)    │    │ Script   │    │ (binary) │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│                                                              │
│  OTA WIDGETS (server-delivered):                            │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │ .rfwtxt  │───>│ Server   │───>│  .rfw    │──> CDN/API   │
│  │ (CMS)    │    │ Compiler │    │ (binary) │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Build Script Implementation

For Option A/B, create `tool/compile_rfw.dart`:

```dart
// tool/compile_rfw.dart
import 'dart:io';
import 'package:rfw/formats.dart';

void main() async {
  final sourceDir = Directory('assets/rfw/source');
  final outputDir = Directory('assets/rfw/defaults');

  await for (final file in sourceDir.list()) {
    if (file.path.endsWith('.rfwtxt')) {
      final source = await File(file.path).readAsString();
      final parsed = parseLibraryFile(source);
      final binary = encodeLibraryBlob(parsed);

      final outputPath = file.path
          .replaceFirst('source', 'defaults')
          .replaceFirst('.rfwtxt', '.rfw');
      await File(outputPath).writeAsBytes(binary);

      print('Compiled: ${file.path} -> $outputPath');
    }
  }
}
```

Add to CI:
```yaml
# .github/workflows/build.yml
- name: Compile RFW assets
  run: dart run tool/compile_rfw.dart
```

### Decision Factors

| Factor | Build-Time (B) | Server-Side (C) |
|--------|----------------|-----------------|
| Bundled fallback assets | Required | N/A |
| OTA widget updates | N/A | Required |
| Non-dev widget authoring | No | Yes |
| Compilation errors caught | At build time | At upload time |
| Requires server infrastructure | No | Yes |

### Recommendation

| Context | Recommendation |
|---------|----------------|
| Spike/Prototype | Local script (Option A) |
| Production | CI (Option B) + Server-side (Option C) |

---

## Question 4: Error UI Design

**What renders when remote widget fails?**

### Why This Matters

DESIGN.md Section 7.4 acknowledges failure scenarios:
- Malformed widget definitions
- Missing data in DynamicContent
- Unknown widget types
- Stack overflow from recursive definitions
- Network failures during load

Without explicit error UI design, failures result in either crashes or confusing blank screens.

### Failure Scenarios & Options

| Scenario | Option A: Blank | Option B: Placeholder | Option C: Error Card | Option D: Fallback Widget |
|----------|-----------------|----------------------|---------------------|--------------------------|
| Missing data key | Empty text | "—" or skeleton | "Data unavailable" | Last known good value |
| Unknown widget type | Nothing renders | Gray box with name | "Widget not supported" | SizedBox |
| Parse error | Crash | Nothing | Error details | Bundled fallback |
| Network timeout | Nothing | Loading skeleton | "Check connection" | Cached version |
| Recursive overflow | Crash | Nothing | "Rendering error" | Bundled fallback |

### Recommended Approach: Layered Error Handling

```
┌─────────────────────────────────────────────────────────────┐
│                    ERROR HANDLING LAYERS                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Layer 1: Data Defaults (transparent to user)               │
│  ├─ Missing string → empty string ""                        │
│  ├─ Missing number → 0                                      │
│  └─ Missing list → empty list []                            │
│                                                              │
│  Layer 2: Widget Fallbacks (minimal disruption)             │
│  ├─ Unknown widget → SizedBox.shrink()                      │
│  └─ Failed child → Container with error border (debug only) │
│                                                              │
│  Layer 3: Screen-Level Recovery (user sees error state)     │
│  ├─ Parse failure → ErrorCard with retry button             │
│  ├─ Network failure → "Offline mode" banner + cached UI     │
│  └─ Catastrophic → Full-screen error + contact support      │
│                                                              │
│  Layer 4: Crash Prevention (last resort)                    │
│  ├─ Stack overflow → catch, log, show ErrorWidget           │
│  └─ Unhandled exception → global handler, don't crash       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Example

```dart
// lib/core/rfw/runtime/safe_remote_widget.dart
class SafeRemoteWidget extends StatelessWidget {
  final Runtime runtime;
  final DynamicContent data;
  final FullyQualifiedWidgetName widget;
  final Widget Function()? fallbackBuilder;
  final void Function(Object error, StackTrace stack)? onError;

  const SafeRemoteWidget({
    required this.runtime,
    required this.data,
    required this.widget,
    this.fallbackBuilder,
    this.onError,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stack) {
        onError?.call(error, stack);
        // Report to crash analytics
        CrashReporting.recordError(error, stack, reason: 'RFW render failure');
      },
      fallback: fallbackBuilder?.call() ?? _defaultErrorWidget(),
      child: RemoteWidget(
        runtime: runtime,
        data: data,
        widget: widget,
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange),
          const SizedBox(height: 8),
          const Text('Unable to load content'),
          TextButton(
            onPressed: () { /* trigger reload */ },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

### Design Questions to Answer

1. **Debug vs Release:** Show stack traces in debug, friendly messages in release?
2. **Retry behavior:** Automatic retry with backoff, or manual retry button?
3. **Partial failures:** If one widget in a list fails, hide it or show error in-place?
4. **Logging:** What context to capture? Widget ID, data snapshot, client version?
5. **User communication:** "Something went wrong" vs specific guidance?

### Recommendation

| Context | Recommendation |
|---------|----------------|
| Spike/Prototype | Layered approach with debug details |
| Production | Layered approach + analytics integration |

---

## Question 5: Performance Targets

**Acceptable latency for widget load and text input?**

### Why This Matters

DESIGN.md identifies two performance-critical paths:

1. **Widget Load Time:** User waits for UI to appear
2. **Text Input Round-Trip:** User types, event fires, state updates, UI refreshes

Without targets, you can't objectively evaluate if the implementation is acceptable.

### Industry Benchmarks

| Metric | Poor | Acceptable | Good | Excellent |
|--------|------|------------|------|-----------|
| Initial widget render | >3s | 1-3s | 500ms-1s | <500ms |
| Cached widget render | >500ms | 200-500ms | 100-200ms | <100ms |
| Network fetch (cold) | >5s | 2-5s | 1-2s | <1s |
| Text input latency | >200ms | 100-200ms | 50-100ms | <50ms |
| Frame rate during scroll | <30fps | 30-45fps | 45-55fps | 60fps |

### Widget Load Timeline

```
┌─────────────────────────────────────────────────────────────┐
│                 WIDGET LOAD TIMELINE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  T0: Navigation intent                                       │
│   │                                                          │
│   ├─ T1: Check cache ─────────────────────┐                 │
│   │       (target: <10ms)                  │                 │
│   │                                        │                 │
│   ├─ T2a: Cache hit → Parse binary        │                 │
│   │        (target: <50ms)                 │                 │
│   │                                        │                 │
│   ├─ T2b: Cache miss → Network fetch ─────┤                 │
│   │        (target: <2000ms)               │                 │
│   │                                        │                 │
│   ├─ T3: Build DynamicContent             │                 │
│   │       (target: <20ms)                  │                 │
│   │                                        │                 │
│   └─ T4: First frame rendered ◄───────────┘                 │
│          (total target: <500ms cached, <3000ms network)     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Text Input Round-Trip Timeline

```
┌─────────────────────────────────────────────────────────────┐
│                TEXT INPUT ROUND-TRIP                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  T0: Keystroke                                               │
│   │                                                          │
│   ├─ T1: onChanged event fires ──────────┐                  │
│   │       (target: <5ms)                  │                  │
│   │                                       │                  │
│   ├─ T2: Handler processes event          │                  │
│   │       (target: <10ms)                 │                  │
│   │                                       │                  │
│   ├─ T3: State update (Bloc/Provider)     │                  │
│   │       (target: <10ms)                 │                  │
│   │                                       │                  │
│   ├─ T4: DynamicContent regenerated       │                  │
│   │       (target: <10ms)                 │                  │
│   │                                       │                  │
│   └─ T5: UI reflects new state ◄──────────┘                 │
│          (total target: <50ms for responsive feel)          │
│                                                              │
│  DEBOUNCE STRATEGY (for validation):                        │
│  ├─ Visual feedback: immediate (no debounce)                │
│  └─ Validation logic: 300ms debounce                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Proposed Targets

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Cached widget render | <200ms | Stopwatch in code, DevTools timeline |
| Network widget load | <3s (P95) | Analytics event tracking |
| Binary parse time | <50ms | Stopwatch around `decodeLibraryBlob` |
| Text input visual feedback | <50ms | DevTools frame analysis |
| Scroll performance | 60fps | DevTools performance overlay |
| DynamicContent build | <20ms | Stopwatch around transformer |

### Monitoring Implementation

```dart
// lib/core/rfw/runtime/performance_monitor.dart
class RfwPerformanceMonitor {
  static void trackWidgetLoad(
    String widgetId,
    Duration duration, {
    bool cached = false,
  }) {
    Analytics.track('rfw_widget_load', {
      'widget_id': widgetId,
      'duration_ms': duration.inMilliseconds,
      'source': cached ? 'cache' : 'network',
    });

    // Alert if exceeding targets
    if (cached && duration.inMilliseconds > 200) {
      debugPrint('WARNING: Cached widget load exceeded 200ms target');
    }
    if (!cached && duration.inMilliseconds > 3000) {
      debugPrint('WARNING: Network widget load exceeded 3s target');
    }
  }

  static void trackTextInputLatency(Duration duration) {
    if (duration.inMilliseconds > 50) {
      debugPrint('WARNING: Text input latency ${duration.inMilliseconds}ms exceeds 50ms target');
    }
  }
}
```

### Recommendation

| Context | Recommendation |
|---------|----------------|
| Spike/Prototype | 200ms cached, 3s network targets |
| Production | Same targets + monitoring dashboard |

---

## Question 6: Security Review

**Who performs security assessment of RFW integration?**

### Why This Matters

DESIGN.md Section 7.4 identifies security risks:
> "A malicious or buggy server response could define an infinitely deep recursion of widgets... causing a stack overflow crash"

RFW is not arbitrary code execution, but it **is** a vector for:
- Denial of Service (crash the app)
- UI spoofing (fake login screens)
- Data exfiltration (if events capture sensitive data)
- Resource exhaustion (memory, CPU)

### Threat Model

| Threat | Vector | Impact | Likelihood |
|--------|--------|--------|------------|
| **App Crash (DoS)** | Recursive widget definition | User can't use app | Medium (if server compromised) |
| **UI Spoofing** | Fake "Enter password" widget | Credential theft | Low (requires server control) |
| **Resource Exhaustion** | Massive widget tree | Battery drain, OOM | Medium |
| **Data Leakage** | Events sending PII to malicious endpoint | Privacy violation | Low (events go to your handler) |
| **Server Compromise** | Attacker controls widget server | All of the above | Depends on server security |

### Security Review Scope

```
┌─────────────────────────────────────────────────────────────┐
│                 SECURITY REVIEW AREAS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. TRANSPORT SECURITY                                       │
│     □ HTTPS enforced for .rfw downloads                     │
│     □ Certificate pinning (optional, high-security)         │
│     □ No sensitive data in widget request URLs              │
│                                                              │
│  2. SERVER TRUST                                             │
│     □ Widget binary signature verification                  │
│     □ Server authentication                                 │
│     □ Response validation (size limits, format checks)      │
│                                                              │
│  3. CLIENT HARDENING                                         │
│     □ Widget tree depth limits                              │
│     □ Rendering timeout                                     │
│     □ Memory limits for parsed widgets                      │
│     □ Stack overflow caught (not crash)                     │
│                                                              │
│  4. DATA FLOW                                                │
│     □ DynamicContent doesn't include secrets                │
│     □ Events don't leak PII                                 │
│     □ Error reports sanitized                               │
│                                                              │
│  5. FALLBACK SECURITY                                        │
│     □ Bundled fallbacks can't be replaced by attacker       │
│     □ Cache poisoning prevented                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Review Options

| Option | Who | When | Depth |
|--------|-----|------|-------|
| **A. Self-Review** | Development team | During implementation | Basic |
| **B. Internal Security Team** | Dedicated security engineers | Before Stage 10 gate | Moderate |
| **C. External Penetration Test** | Third-party security firm | Before production launch | Deep |
| **D. Bug Bounty** | Security researchers | After launch | Ongoing |

### Recommended Approach

**For spike/prototype:** Option A (self-review checklist)

**For production:**
1. Option B (internal review) at Stage 9 completion
2. Option C (external pentest) before first production deployment
3. Option D (bug bounty) 3-6 months post-launch

### Self-Review Checklist

```markdown
## RFW Security Self-Review Checklist

### Transport
- [ ] All .rfw fetches use HTTPS
- [ ] No API keys or tokens in widget request URLs
- [ ] Server responses have appropriate cache headers

### Parsing
- [ ] Widget tree depth limited to N levels (recommend: 100)
- [ ] Parse timeout implemented (recommend: 5 seconds)
- [ ] Stack overflow errors caught and logged

### Data
- [ ] DynamicContent reviewed for PII exposure
- [ ] Event payloads reviewed - no sensitive data sent
- [ ] Error reports don't include user data

### Cache
- [ ] Cache stored in app-private directory
- [ ] Cache invalidation on user logout (if applicable)
- [ ] Bundled fallbacks verified at build time

### Reviewed by: _______________ Date: _______________
```

### Implementation: Secure Runtime Wrapper

```dart
// lib/core/rfw/runtime/secure_runtime.dart
class SecureRuntime {
  static const int maxWidgetDepth = 100;
  static const Duration parseTimeout = Duration(seconds: 5);
  static const int maxBinarySize = 5 * 1024 * 1024; // 5MB

  static Future<RemoteWidgetLibrary> parseSecurely(Uint8List binary) async {
    // Size check
    if (binary.length > maxBinarySize) {
      throw SecurityException('Widget binary exceeds maximum size');
    }

    // Timeout wrapper
    return await Future.any([
      Future(() => decodeLibraryBlob(binary)),
      Future.delayed(parseTimeout).then((_) {
        throw TimeoutException('Widget parsing exceeded ${parseTimeout.inSeconds}s');
      }),
    ]);
  }

  static Widget buildSecurely({
    required Runtime runtime,
    required DynamicContent data,
    required FullyQualifiedWidgetName widget,
    required Widget fallback,
  }) {
    try {
      return RemoteWidget(
        runtime: runtime,
        data: data,
        widget: widget,
      );
    } on StackOverflowError catch (e, stack) {
      _reportSecurityIncident('stack_overflow', e, stack);
      return fallback;
    } catch (e, stack) {
      _reportSecurityIncident('render_failure', e, stack);
      return fallback;
    }
  }

  static void _reportSecurityIncident(
    String type,
    Object error,
    StackTrace stack,
  ) {
    // Log to security monitoring
    debugPrint('SECURITY: RFW $type incident');
    // In production: send to security monitoring service
  }
}
```

### Recommendation

| Context | Recommendation |
|---------|----------------|
| Spike/Prototype | Self-review checklist (Option A) |
| Production | Internal + External pentest (Options B + C) |

---

## Decision Summary

| Question | Options | Spike Recommendation | Production Recommendation |
|----------|---------|----------------------|---------------------------|
| **2. Server Backend** | Static hosting, API, CMS, Other team, Mock | Mock server | API server with versioning |
| **3. Compilation Pipeline** | Local script, CI/CD, Server-side | Local script | CI + Server-side |
| **4. Error UI Design** | Blank, Placeholder, Error card, Fallback | Layered approach | Layered + analytics |
| **5. Performance Targets** | Various thresholds | 200ms cached, 3s network | Same + monitoring |
| **6. Security Review** | Self, Internal, External, Bounty | Self-review checklist | Internal + External pentest |

---

## Next Steps

After decisions are made on these questions:

1. Update PLAN.md with chosen approaches
2. Add specific tasks for chosen options to relevant stages
3. Document decisions in project ADR (Architecture Decision Records) if applicable
4. Proceed with Stage 1 implementation

---

## Appendix: Quick Reference

### Server Endpoint Spec (Question 2)

```
GET /widgets/{widget_id}.rfw
Headers: X-Client-Widget-Version, X-Platform, X-App-Version
Responses: 200 (binary), 404 (not found), 406 (version mismatch)
```

### Performance Targets (Question 5)

| Metric | Target |
|--------|--------|
| Cached render | <200ms |
| Network load | <3s P95 |
| Binary parse | <50ms |
| Text input | <50ms |
| Scroll | 60fps |

### Security Limits (Question 6)

| Limit | Value |
|-------|-------|
| Widget depth | 100 levels |
| Parse timeout | 5 seconds |
| Binary size | 5MB |
