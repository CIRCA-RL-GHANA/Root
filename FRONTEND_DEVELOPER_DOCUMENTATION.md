# Frontend Developer Documentation

Flutter 3.2+ mobile and Progressive Web App (PWA) for the PROMPT Genie platform.  
State: Provider 6 + Riverpod 2 · HTTP: Dio 5 · Local storage: Hive + SharedPreferences

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Setup (Local Development)](#setup-local-development)
3. [Architecture Overview](#architecture-overview)
4. [Core Layer](#core-layer)
5. [State Management](#state-management)
6. [Network Layer (API Client)](#network-layer-api-client)
7. [Authentication Flow](#authentication-flow)
8. [AI Integration](#ai-integration)
9. [Navigation / Routing](#navigation--routing)
10. [Theming](#theming)
11. [Feature Modules](#feature-modules)
12. [Adding a New Screen](#adding-a-new-screen)
13. [Build & Release](#build--release)

---

## Project Structure

```
thepg/
├── lib/
│   ├── main.dart                     # App entry point
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── env_config.dart       # API base URL, WS URL
│   │   │   └── error_codes.dart      # Typed error code constants
│   │   ├── network/
│   │   │   └── api_client.dart       # Dio singleton, JWT interceptor, token refresh
│   │   ├── providers/
│   │   │   └── app_providers.dart    # Provider list (all ChangeNotifier providers)
│   │   ├── routes/
│   │   │   └── app_routes.dart       # Route name constants + onGenerateRoute
│   │   ├── services/
│   │   │   ├── ai_service.dart            # AI REST client (50+ methods)
│   │   │   ├── ai_assistant_service.dart  # Conversational AI NLP client
│   │   │   ├── ai_insights_notifier.dart  # ChangeNotifier — AI insights for screens
│   │   │   ├── wishlist_service.dart
│   │   │   ├── ride_service.dart
│   │   │   ├── order_service.dart
│   │   │   ├── product_service.dart
│   │   │   ├── profile_service.dart
│   │   │   ├── chat_service.dart
│   │   │   ├── subscription_service.dart
│   │   │   ├── planner_service.dart
│   │   │   └── social_service.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Material theme (light + dark)
│   │   └── utils/
│   │       └── validators.dart       # Form field validators
│   │
│   ├── features/
│   │   ├── alerts/                   # Alert notifications (12 screens)
│   │   ├── april/                    # Finance calendar (7 screens)
│   │   ├── go/                       # GO wallet (24 screens)
│   │   ├── live/                     # Fulfilment & driver ops (23 screens)
│   │   ├── market/                   # E-commerce (17 screens)
│   │   ├── onboarding/               # Auth flow (14 screens)
│   │   ├── other/
│   │   ├── prompt/                   # AI assistant dashboard
│   │   ├── qualchat/                 # Messaging (16 screens)
│   │   ├── setup_dashboard/          # Business onboarding (34 screens)
│   │   ├── updates/                  # Social feed (13 screens)
│   │   ├── user_details/             # Profile & security (9 screens)
│   │   └── utility/                  # Settings & help (9 screens)
│   │
│   ├── models/                       # Shared data models
│   ├── services/                     # Additional business logic services
│   └── widgets/                      # Reusable UI components
│
├── assets/
│   ├── animations/                   # Lottie JSON files
│   ├── icons/                        # SVG icons
│   ├── images/                       # PNG/JPG assets
│   └── fonts/
│       └── Poppins-{weight}.ttf
│
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/AndroidManifest.xml
│   └── keystore/                     # Release keystore (gitignored)
│
├── ios/
│   ├── Runner/
│   └── Podfile
│
├── web/
│   ├── index.html
│   └── manifest.json                 # PWA manifest
│
├── test/                             # Unit tests
├── pubspec.yaml                      # Dependencies
└── build-all.sh                      # Build all targets script
```

---

## Setup (Local Development)

### Prerequisites

- Flutter SDK 3.2+ (check: `flutter --version`)
- Android Studio or Xcode (for device simulators)
- Backend running at `http://localhost:3000` (or update `EnvConfig.baseUrl`)

### Steps

```bash
cd thepg

# 1. Install dependencies
flutter pub get

# 2. Run code generation (if using build_runner)
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app
flutter run                     # Select device interactively
flutter run -d emulator-5554    # Specific Android emulator
flutter run -d iPhone-15        # Specific iOS simulator
flutter run -d chrome           # PWA in Chrome
```

### Update API URL

Edit `lib/core/constants/env_config.dart`:

```dart
class EnvConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS / web
  // static const String baseUrl = 'https://api.genieinprompt.app/api/v1'; // production
  
  static const String wsUrl = 'wss://api.genieinprompt.app/socket.io/chat';
}
```

---

## Architecture Overview

```
App Bootstrap (main.dart)
  └── MultiProvider (AppProviders.providers)
        └── MaterialApp
              └── onGenerateRoute (AppRoutes)
                    └── Screen Widget
                          ├── Consumer<SomeProvider>   (Provider state)
                          ├── ConsumerWidget            (Riverpod state)
                          └── ApiClient.instance.get()  (direct calls)
```

### Layering

| Layer | Location | Purpose |
|---|---|---|
| UI | `features/*/screens/` | Widgets, layout, user interaction |
| Provider | `features/*/providers/` | State management (ChangeNotifier) |
| Service | `core/services/` | Business logic, API calls |
| Network | `core/network/api_client.dart` | Dio HTTP client, JWT |
| Storage | Hive + SharedPreferences | Local persistence |
| Models | `models/` + `features/*/models/` | Data classes |

---

## Core Layer

### App Bootstrap (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ApiClient.instance.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const PromptGenieApp());
}
```

`ApiClient.instance.init()` loads saved tokens from SharedPreferences so the user stays logged in across app restarts.

---

## State Management

The app uses two parallel state management approaches:

### Provider (primary — most screens)

```dart
// 1. Define a ChangeNotifier
class GoProvider extends ChangeNotifier {
  double _balance = 0;
  double get balance => _balance;

  Future<void> loadBalance() async {
    _balance = await GoService.instance.getBalance();
    notifyListeners();
  }
}

// 2. Register in AppProviders
static final List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => GoProvider()),
  ChangeNotifierProvider(create: (_) => AIInsightsNotifier()),
  // ...
];

// 3. Consume in UI
Consumer<GoProvider>(
  builder: (context, go, _) {
    return Text('Balance: ${go.balance}');
  },
)

// 4. Read without rebuilding
context.read<GoProvider>().loadBalance();
```

### Riverpod (select screens)

Used in screens that require fine-grained state control (e.g. `live_operations_screen.dart`, `qualchat_premium_screen.dart`).

```dart
final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  return RideNotifier();
});

// In a ConsumerWidget or ConsumerStatefulWidget:
final rideState = ref.watch(rideProvider);
```

---

## Network Layer (API Client)

`lib/core/network/api_client.dart` — singleton Dio client.

### Usage

```dart
// GET
final response = await ApiClient.instance.get('/products?status=active');
final products = (response.data['data'] as List)
    .map((e) => ProductModel.fromJson(e))
    .toList();

// POST
final response = await ApiClient.instance.post('/rides', data: {
  'riderId': userId,
  'pickupLocation': { 'latitude': lat, 'longitude': lng },
});

// PATCH
await ApiClient.instance.patch('/orders/$id/status', data: { 'status': 'confirmed' });

// File upload
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
});
await ApiClient.instance.post('/files/upload', data: formData);
```

### JWT Interceptor

The client automatically:
1. Attaches `Authorization: Bearer <token>` to every request
2. On `401 Unauthorized` → calls `POST /auth/refresh`
3. Retries the original request with the new access token
4. If refresh fails → redirects user to login screen

### Token Storage

| Token | Storage | Key |
|---|---|---|
| Access token | SharedPreferences | `auth_access_token` |
| Refresh token | SharedPreferences | `auth_refresh_token` |

```dart
// Save tokens after login
await ApiClient.instance.saveTokens(accessToken, refreshToken);

// Clear on logout
await ApiClient.instance.clearTokens();
```

---

## Authentication Flow

### Onboarding Screens (14 total)

```
1. SplashScreen           → checks saved token → home or onboarding
2. PhoneEntryScreen        → user enters phone number
3. OtpVerificationScreen   → 6-digit OTP via SMS
4. PasswordCreationScreen  → create password (bcrypt on server)
5. RoleSelectionScreen     → individual / business / driver
6. ProfileSetupScreen      → name, avatar, bio
7. BiometricSetupScreen    → optional Face ID / fingerprint
8. PermissionsScreen       → location, camera, notifications
9. EntityCreationScreen    → create entity (individual or business)
10. BranchSetupScreen      → (business only) add first branch
11. SubscriptionScreen     → select plan
12. InterestsScreen        → pick interest tags
13. SuccessScreen          → welcome animation
14. HomeScreen             → PROMPT dashboard
```

### Token Persistence

After successful login, tokens are saved to SharedPreferences. On next app launch, `ApiClient.init()` loads them and the user is taken directly to the home screen.

---

## AI Integration

All 180 screens include an AI insights strip using `AIInsightsNotifier`.

### AIInsightsNotifier

`ChangeNotifier` that holds a list of AI insights fetched from the backend.

```dart
class AIInsightsNotifier extends ChangeNotifier {
  List<Map<String, dynamic>> _insights = [];
  List<Map<String, dynamic>> get insights => _insights;

  Future<void> loadInsights(String userId, String module) async {
    _insights = await AiService.instance.getInsights(userId, module);
    notifyListeners();
  }
}
```

### AI Widget Pattern

Every screen includes this `Consumer` widget in its widget tree:

```dart
Consumer<AIInsightsNotifier>(
  builder: (context, ai, _) {
    if (ai.insights.isEmpty) return const SizedBox.shrink();
    return Container(
      color: kModuleColor.withOpacity(0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        const Icon(Icons.auto_awesome, size: 14, color: kModuleColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI: ${ai.insights.first['title'] ?? ''}',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  },
),
```

**Note:** Access insight data as `ai.insights.first['title']` (Map key access), not `.label`.

### Module Colors

| Module | Color Constant |
|---|---|
| GO | `kGoColor` |
| Live | `kLiveColor` |
| QualChat | `kChatColor` (`0xFF06B6D4`) |
| Updates | `kUpdatesColor` |
| Alerts | `kAlertsColor` |
| Market | `kMarketColor` |
| Utility | `kUtilityColor` |
| Setup Dashboard | `kSetupColor` |
| APRIL | `kAprilColor` |

### AI Service (`ai_service.dart`)

50+ methods covering all platform domains:

```dart
// Ride pricing
final pricing = await AiService.instance.getDynamicPricing(rideContext);

// Fraud check
final fraud = await AiService.instance.getFraudScore(transactionData);

// Product recommendations
final recs = await AiService.instance.getProductRecommendations(userId);

// Sentiment analysis
final sentiment = await AiService.instance.analyzeMessageSentiment(text);

// Financial insights
final insights = await AiService.instance.getFinancialInsights(userId);

// Semantic search
final results = await AiService.instance.semanticSearch(query);
```

---

## Navigation / Routing

`lib/core/routes/app_routes.dart` defines all route names and `onGenerateRoute`.

### Route Constants

```dart
class AppRoutes {
  static const String preLoading = '/preloading';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // GO module
  static const String goHub = '/go/hub';
  static const String goTransfer = '/go/transfer';
  static const String goBatchPayments = '/go/batch-payments';

  // Market module
  static const String marketHub = '/market/hub';
  static const String marketProduct = '/market/product';
  static const String marketCheckout = '/market/checkout';

  // ... all other routes
}
```

### Navigation

```dart
// Push named route
Navigator.pushNamed(context, AppRoutes.goTransfer);

// Push with arguments
Navigator.pushNamed(context, AppRoutes.marketProduct,
    arguments: {'productId': id});

// Replace (no back button)
Navigator.pushReplacementNamed(context, AppRoutes.home);

// Pop to root
Navigator.popUntil(context, ModalRoute.withName(AppRoutes.home));
```

### Route Arguments

```dart
// In receiving screen
@override
Widget build(BuildContext context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  final productId = args['productId'] as String;
  // ...
}
```

---

## Theming

`lib/core/theme/app_theme.dart`

### Typography

All text uses **Poppins** (configured as `fontFamily` in `ThemeData`). Weights used: 400 (regular), 500 (medium), 600 (semibold), 700 (bold).

```dart
// Usage
Text(
  'Hello',
  style: Theme.of(context).textTheme.headlineMedium,
)

// Or direct
const TextStyle(
  fontFamily: 'Poppins',
  fontSize: 16,
  fontWeight: FontWeight.w600,
)
```

### Dark Background Palette

| Element | Color |
|---|---|
| Background | `#0F0F23` |
| Surface | `#1A1A2E` |
| Primary | Brand accent |
| Error | `#F44336` |

### Text Scaling

Text scaling is capped in `main.dart` to prevent layout breakage on accessibility font sizes:

```dart
builder: (context, child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(
        MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
      ),
    ),
    child: child!,
  );
},
```

---

## Feature Modules

Each feature follows this structure:

```
features/example/
├── models/
│   └── example_model.dart          # Data class (fromJson / toJson)
├── providers/
│   └── example_provider.dart       # ChangeNotifier or StateNotifier
├── screens/
│   ├── example_hub_screen.dart     # Main hub
│   └── example_detail_screen.dart
└── widgets/
    └── example_card_widget.dart    # Reusable screen-specific widgets
```

### Feature Summary

| Feature | Screens | Key Providers |
|---|---|---|
| Onboarding | 14 | `OnboardingProvider` |
| PROMPT | 1 | `AIInsightsNotifier` |
| GO | 21 | `GoProvider`, `WalletProvider`, `TransactionProvider` |
| Market | 16 | `MarketProvider`, `CartProvider`, `OrderProvider` |
| Live | 23 | `LiveProvider`, `DeliveryProvider` |
| QualChat | 17 | `ChatProvider`, `MessageProvider` |
| APRIL | 7 | `PlannerProvider`, `StatementProvider` |
| Updates | 13 | `FeedProvider`, `PostProvider` |
| Setup Dashboard | 32 | `SetupProvider`, `EntityProvider` |
| User Details | 8 | `ProfileProvider`, `SecurityProvider` |
| Utility | 5 | — (stateless or simple) |
| Alerts | 3 | `AlertsProvider` |

---

## Adding a New Screen

### 1. Create the Screen File

```dart
// lib/features/go/screens/go_new_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ai_insights_notifier.dart';

class GoNewScreen extends StatefulWidget {
  const GoNewScreen({super.key});

  @override
  State<GoNewScreen> createState() => _GoNewScreenState();
}

class _GoNewScreenState extends State<GoNewScreen> {
  @override
  void initState() {
    super.initState();
    // Load AI insights for this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIInsightsNotifier>().loadInsights(userId, 'go');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Feature')),
      body: Column(
        children: [
          // AI insights strip (required on all screens)
          Consumer<AIInsightsNotifier>(
            builder: (context, ai, _) {
              if (ai.insights.isEmpty) return const SizedBox.shrink();
              return Container(
                color: kGoColor.withOpacity(0.07),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, size: 14, color: kGoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI: ${ai.insights.first['title'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              );
            },
          ),
          // Main content
          const Expanded(child: Center(child: Text('Content here'))),
        ],
      ),
    );
  }
}
```

### 2. Register the Route

```dart
// lib/core/routes/app_routes.dart
static const String goNew = '/go/new';

// In onGenerateRoute:
case AppRoutes.goNew:
  return MaterialPageRoute(builder: (_) => const GoNewScreen());
```

### 3. Navigate to It

```dart
Navigator.pushNamed(context, AppRoutes.goNew);
```

---

## Build & Release

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK (requires keystore)
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

**Keystore setup:** See `android/keystore.properties.example`. Copy to `android/keystore.properties` and fill in keystore path and passwords.

### iOS

```bash
# Debug
flutter build ios --debug

# Release (requires Apple developer certificate)
flutter build ios --release
```

Archive and distribute via Xcode (`ios/Runner.xcworkspace`).

### PWA / Web

```bash
flutter build web --release --web-renderer canvaskit
```

Output in `build/web/`. Deploy to Nginx:

```nginx
location /pwa/ {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /pwa/index.html;
}
```

### Build All Targets

```bash
./build-all.sh
```

### Environment for Release

Update `lib/core/constants/env_config.dart` with production URLs before building release binaries:

```dart
static const String baseUrl = 'https://api.genieinprompt.app/api/v1';
static const String wsUrl = 'wss://api.genieinprompt.app/socket.io/chat';
```

---

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | Primary state management |
| `flutter_riverpod` | ^2.4.9 | Secondary state management |
| `dio` | ^5.4.0 | HTTP client with interceptors |
| `hive` + `hive_flutter` | ^2.2.3 | Local NoSQL storage |
| `shared_preferences` | ^2.2.2 | Simple key-value storage |
| `local_auth` | ^2.1.8 | Biometrics (fingerprint / Face ID) |
| `geolocator` | ^11.0.0 | GPS location |
| `image_picker` | ^1.0.5 | Camera / gallery |
| `image_cropper` | ^5.0.1 | Image cropping |
| `lottie` | ^3.0.0 | Lottie animations |
| `shimmer` | ^3.0.0 | Skeleton loading states |
| `cached_network_image` | ^3.3.1 | Cached image loading |
| `pinput` | ^4.0.0 | PIN entry field |
| `connectivity_plus` | ^5.0.2 | Network status |
| `permission_handler` | ^11.1.0 | Runtime permissions |
| `intl` | ^0.19.0 | Date/number formatting |
| `url_launcher` | ^6.2.2 | Open URLs, phone, email |
