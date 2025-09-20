# AgroTech App Blueprint

## Overview

This document outlines the development plan and features for the AgroTech application. The goal is to build a modern and user-friendly Flutter application for the agricultural technology sector.

## Current State

The application now features a modern and visually appealing dashboard that connects to a Firebase Realtime Database. The dashboard displays live data for temperature, humidity, and water tank level. The app is also configured to receive push notifications for critical alerts.

### Key Features Implemented:

*   **Modern UI:** A redesigned dashboard with a clean layout, informative cards, and custom icons.
*   **Material 3 Theming:** A sophisticated theming system with a custom color palette and typography using `google_fonts`.
*   **Light/Dark Mode:** A theme provider that allows users to switch between light and dark modes.
*   **Firebase Realtime Database Integration:** The application is connected to a Firebase Realtime Database to display live sensor data.
*   **Live Data Display:** The dashboard displays real-time data for:
    *   Temperature
    *   Humidity
    *   Water Tank Level (calculated from a distance sensor)
*   **Push Notifications:** The app is configured to receive push notifications from Firebase Cloud Messaging. It requests notification permissions, obtains an FCM token, and saves it to Firestore. This enables the backend to send targeted notifications to the device.

## Plan for Future Enhancements

My next steps will focus on adding more advanced features and improving the user experience. Here are some of the planned enhancements:

*   **Data Visualization:** Implement charts and graphs to visualize historical sensor data.
*   **User Authentication:** Add user authentication to personalize the app experience and secure user data.
*   **Device Control:** Allow users to control their smart irrigation devices directly from the app.
*   **Crop Management:** Add features for managing crop cycles, tracking growth, and optimizing irrigation schedules.
*   **Pest and Disease Detection:** Integrate a machine learning model to detect pests and diseases from images.
