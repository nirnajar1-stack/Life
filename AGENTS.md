# Life App - Project Cursor Rules & Guidelines

## 1. Tech Stack & Core Libraries
- Framework: Flutter (Dart 3.x)
- Platforms: Android & Web (Single Codebase, Responsive Layouts)
- Backend & Database: Supabase Flutter SDK (`supabase_flutter`)
- State Management: Riverpod (`flutter_riverpod`) or Clean ChangeNotifier/StateNotifier
- Native Android Components: Kotlin for Android Home Widgets (`home_widget` integration)

## 2. Architecture & Directory Structure
Follow a strict feature-first Layered Architecture to ensure separate layers for UI, Business Logic, and Data.
- `lib/features/`: Group by feature (e.g., `expenses`, `tasks`, `health`).
  Inside each feature:
  - `data/`: Models, Repositories (Direct Supabase API integration using async/await).
  - `domain/`: Business logic, state notifiers/providers.
  - `presentation/`: UI screens and components (Stateless/Stateful/ConsumerWidgets).
- Ensure absolute separation: UI widgets must NEVER call Supabase methods directly. They must go through the Repository layer.

## 3. Supabase & Database Conventions
- Database structure is flat (No complex RLS policies for now, single-user context).
- Column mapping: Supabase tables use `snake_case`. Dart models must map these to `camelCase` using clean `fromJson` and `toJson` factory methods.
- Always use proper type-casting for Postgres types (e.g., `int`, `double`, `DateTime.parse()` for timestamps).
- Enable `realtime` listeners only where requested explicitly (e.g., Tasks, Health summaries).

## 4. UI/UX & Responsive Web/Mobile Guidelines
- Design System: Clean, modern, high-contrast, optimized for fast readability.
- Responsiveness: All presentation components must layout adaptively. Use `LayoutBuilder` or responsive breakpoints to handle both Android screens and widescreen Web viewports from any browser.
- UI elements should handle loading and error states gracefully (e.g., AsyncValue when using Riverpod).

## 5. Android Native & Home Widgets Prerequisite
- When writing files inside the `/android` directory: Use modern Kotlin practices, follow standard Android `AppWidgetProvider` architecture, and prepare hooks for deep-linking back into the Flutter application.

## 6. AI & MCP Integration Ready
- Write explicit, atomic functions in the repository layer (e.g., `getExpensesSummary()`, `addTask()`).
- Avoid deeply nested anonymous functions. Keep the codebase declarative and highly readable, making it ready for external tools/MCP AI servers to scan, read, and interpret data models effortlessly.
