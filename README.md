# Agro Teching

A **Flutter** mobile and web app for agricultural technology and smart farming, powered by **Firebase** and **Google Gemini AI**.

## Features

- Smart farming recommendations via **Gemini AI**
- Real-time crop/field data via **Firebase Firestore**
- Firebase Authentication
- Firebase Cloud Functions for backend logic
- Cross-platform: Android, iOS, Web

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| AI | Google Gemini API |
| Database | Firebase Firestore |
| Auth | Firebase Authentication |
| Backend | Firebase Cloud Functions |

## Prerequisites

- Flutter SDK 3.x
- Firebase CLI — `npm install -g firebase-tools`
- Gemini API key — [aistudio.google.com](https://aistudio.google.com)

## Setup

```bash
flutter pub get
flutterfire configure
flutter run
```

## Deploy Functions

```bash
cd functions && npm install
firebase deploy --only functions
```
