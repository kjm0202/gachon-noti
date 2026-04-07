# Product Overview

**Gachon Noti** is a notification service for Gachon University that helps students stay updated with university announcements.

## Core Features
- **RSS Crawling**: Automated collection of university notices from multiple boards (bachelor, scholarship, student affairs, job postings, extracurricular activities, dormitory notices)
- **Push Notifications**: Real-time notifications via Firebase Cloud Messaging
- **Subscription Management**: Users can subscribe to specific notice boards
- **Cross-Platform**: Flutter mobile app (Android/iOS)
- **Multi-Campus Support**: Supports both Global Campus and Medical Campus dormitory notices

## Architecture
- **Backend**: Node.js RSS crawler with Supabase database
- **Frontend**: Flutter app using GetX state management
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Google Sign-In integration
- **Notifications**: Firebase Cloud Messaging + Flutter Local Notifications
- **Monetization**: Google Mobile Ads integration

## Target Users
Gachon University students who need timely updates on university announcements and notices.