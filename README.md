# 🐙 Pulpo

Pulpo is a personal offline-first budget tracker designed to help users manage their finances, track spending, plan budgets, monitor debts, set financial goals, and understand their financial habits.

The application is built with Flutter and follows an offline-first approach, allowing users to work with their financial data locally while supporting optional cloud synchronization and account-based features.

## 🚀 Features

* Track income and expenses
* Create and manage financial accounts
* Categorize transactions
* Create monthly and custom budgets
* Monitor budget progress
* Track debts and repayment progress
* Set and manage financial goals
* Create recurring transactions
* View financial dashboards and reports
* Monthly calendar for financial activity
* Import financial data
* Export financial data
* Generate PDF financial documents
* Share financial information
* Currency and exchange-rate support
* Multi-currency financial tracking
* Cloud synchronization
* Google Sign-In
* Sign in with Apple
* Local biometric authentication
* Home screen widgets
* Local notifications and reminders
* Subscription and Pro features
* Shared budgets
* Profile and application settings
* Offline-first local database
* Data backup and synchronization
* Secure handling of sensitive financial data

## 💰 Finance Management

Pulpo provides a complete set of tools for personal finance management.

### Transactions

Users can record income and expenses, assign categories, select accounts, add dates and descriptions, and analyze their financial activity over time.

### Budgets

Budgets allow users to define spending limits and monitor how much has already been spent within a selected period.

### Goals

Financial goals help users plan for specific targets and track progress toward reaching them.

### Debts

The application provides dedicated functionality for managing debts and monitoring repayment progress.

### Recurring Transactions

Recurring transactions can be configured for expenses or income that happen regularly, reducing the need for manual entries.

## 📊 Dashboard & Reports

Pulpo includes a financial dashboard with an overview of the user's financial activity.

The application provides:

* Income and expense summaries
* Spending analysis
* Budget progress
* Financial trends
* Monthly calendar
* Charts and visualizations
* Financial reports

Charts and analytics are implemented using `fl_chart`.

## 🔐 Authentication & Security

Pulpo supports both local-first usage and account-based functionality.

Authentication options include:

* Google Sign-In
* Sign in with Apple
* Firebase Authentication
* Local biometric authentication

The application also includes dedicated security and authentication features within its modular architecture.

## ☁️ Cloud & Synchronization

Pulpo uses Firebase for cloud functionality and synchronization.

### Firebase Services

* Firebase Core
* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Functions

The repository also contains a dedicated `functions` directory for server-side Firebase functionality.

The architecture is designed so that the application can continue working locally while synchronizing data when cloud functionality is available.

## 📱 Widgets & Notifications

Pulpo supports system-level integrations that make financial information accessible outside the main application.

Included functionality:

* Home screen widgets
* Local notifications
* Scheduled reminders
* Timezone-aware notifications
* Widget data synchronization

The project uses `home_widget`, `flutter_local_notifications`, `timezone`, and `flutter_timezone`.

## 📦 Import & Export

Pulpo includes dedicated modules for importing and exporting financial data.

Users can:

* Import existing financial data
* Export application data
* Share exported information
* Generate PDF documents
* Work with archived data

The project includes dedicated `import` and `export` feature modules as well as PDF and archive dependencies.

## ⭐ Pro Features

Pulpo includes a dedicated Pro feature layer and subscription system.

The project contains:

* Pro functionality
* Subscription management
* In-app purchases
* Subscription-related backend functionality

The Flutter application uses the official `in_app_purchase` packages, while the project also contains dedicated `pro` and `subscriptions` modules.

## 👥 Shared Budgets

Pulpo includes support for shared budgets, allowing financial planning to extend beyond a single user.

The feature is implemented as a dedicated module:

```text
features/
└── shared_budget/
```

This provides a foundation for collaborative financial management.

## 🛠️ Tech Stack

* Framework: Flutter
* Language: Dart
* State Management: Riverpod
* Navigation: GoRouter
* Local Database: Drift
* Database Engine: SQLite
* Cloud Database: Firebase Firestore
* Authentication: Firebase Auth
* Cloud Backend: Firebase Cloud Functions
* Charts: FL Chart
* Authentication: Google Sign-In / Apple Sign-In
* Local Security: Local Auth
* Notifications: Flutter Local Notifications
* Widgets: Home Widget
* PDF Generation: PDF
* Archive Processing: Archive
* HTTP: HTTP
* Localization: Flutter Localizations / Intl
* IDs: UUID
* Icons: Lucide Flutter

The current project uses Flutter `>=3.38.0` and Dart `^3.10.0`. The repository version is `1.0.1+20`.

## 📦 Installation

To install Pulpo locally:

1. Clone the repository:

```bash
git clone https://github.com/glebanya13/pulpo.git
```

2. Open the project in Android Studio, VS Code, IntelliJ IDEA, or another Flutter-compatible IDE.

3. Install Flutter dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

For Firebase-backed functionality, make sure the corresponding Firebase project configuration is available before running the application.

## 💻 Usage

After launching Pulpo, users can:

1. Create or configure their financial accounts.
2. Add income and expenses.
3. Organize transactions using categories.
4. Create monthly budgets.
5. Monitor spending and budget progress.
6. Create financial goals.
7. Track debts and repayments.
8. Configure recurring transactions.
9. Review financial statistics and reports.
10. Import or export financial data.
11. Configure notifications and widgets.
12. Sign in to enable account and cloud-related functionality.

## 🧱 Architecture

Pulpo follows a feature-oriented architecture.

The main application code is organized into:

```text
lib/
└── src/
    ├── core/
    ├── data/
    ├── features/
    ├── shell/
    ├── widgets/
    └── router.dart
```

The `features` layer contains independent modules for major areas of the application, while `core` contains shared application functionality and infrastructure.

## 📂 Project Structure

```text
pulpo/
├── android/
├── ios/
├── macos/
│
├── assets/
│   ├── fonts/
│   ├── icon_transparent.png
│   └── splash_icon.png
│
├── functions/
│   ├── certs/
│   ├── scripts/
│   ├── tests/
│   ├── index.js
│   ├── products.js
│   ├── verify.js
│   └── package.json
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   └── src/
│       ├── core/
│       │   ├── l10n/
│       │   ├── notifications/
│       │   ├── pro/
│       │   ├── theme/
│       │   ├── utils/
│       │   ├── app_info.dart
│       │   ├── auto_sync_binder.dart
│       │   ├── currencies.dart
│       │   ├── fx_rate_service.dart
│       │   ├── home_widget_sync.dart
│       │   └── widget_snapshot.dart
│       │
│       ├── data/
│       │   ├── db/
│       │   ├── repositories/
│       │   └── seed/
│       │
│       ├── features/
│       │   ├── accounts/
│       │   ├── auth/
│       │   ├── budgets/
│       │   ├── categories/
│       │   ├── dashboard/
│       │   ├── debts/
│       │   ├── export/
│       │   ├── goals/
│       │   ├── import/
│       │   ├── onboarding/
│       │   ├── pro/
│       │   ├── profile/
│       │   ├── recurring/
│       │   ├── reports/
│       │   ├── security/
│       │   ├── settings/
│       │   ├── shared_budget/
│       │   ├── subscriptions/
│       │   └── transactions/
│       │
│       ├── shell/
│       ├── widgets/
│       └── router.dart
│
├── store/
├── test/
├── .cursor/
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── codemagic.yaml
├── pubspec.yaml
└── README.md
```

The repository currently contains dedicated modules for accounts, authentication, budgets, categories, dashboard, debts, exports, goals, imports, onboarding, Pro, profile, recurring transactions, reports, security, settings, shared budgets, subscriptions, and transactions.

## 🗄️ Local Database

Pulpo uses Drift as its local persistence layer with SQLite.

This provides:

* Structured relational data
* Offline-first operation
* Local transaction storage
* Reliable financial data persistence
* Database migrations
* Repository-based data access

The project includes dedicated database and repository layers under `lib/src/data`.

## 🌍 Localization

The application includes Flutter localization support and uses `intl` for date, number, and currency formatting.

This allows Pulpo to support localized financial information and user-facing content.

## 🧪 Testing

The project contains a dedicated test suite:

```text
test/
```

Firebase Functions also include their own tests:

```text
functions/
└── tests/
```

Run Flutter tests with:

```bash
flutter test
```

For Firebase Functions:

```bash
cd functions
npm test
```

## 🏗️ Backend

Pulpo uses Firebase as its backend infrastructure.

```text
Flutter App
     │
     ├── Drift / SQLite
     │      └── Local financial data
     │
     └── Firebase
            ├── Authentication
            ├── Firestore
            └── Cloud Functions
```

The local database provides the offline-first foundation, while Firebase provides authentication, cloud data, synchronization, and server-side functionality.

## 📱 Supported Platforms

Pulpo is configured as a Flutter mobile application with platform projects for:

* Android
* iOS

The repository also contains a macOS platform project.

## 🔒 Privacy

Pulpo is designed around local-first financial data storage.

The application can keep core financial information available locally while cloud synchronization and account functionality are provided as additional capabilities.

Sensitive operations can also be protected using device-level authentication through the `local_auth` package.

## 🤝 Contributing

Contributions are welcome.

To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Implement your changes.
4. Add or update tests.
5. Run the test suite:

```bash
flutter test
```

6. Submit a pull request.

## 📝 License

No open-source license is currently specified in the repository.

If you plan to distribute Pulpo as an open-source project, add an appropriate `LICENSE` file to the repository.

## 📬 Contact

For questions, suggestions, or bug reports, open an issue in the GitHub repository:

https://github.com/glebanya13/pulpo
