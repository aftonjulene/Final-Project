# BEAST MODE - Fitness Tracking App

Team Name: The Goats
Team Members: Afton Goulding and Ahmed Arshad

Powerpoint presentation link: https://docs.google.com/presentation/d/11BgD_ICOdkdb7ILrFcd9z44WJE-U5nmAbjcyf_GMuVg/edit?usp=sharing

BeastMode is a cross-platform fitness tracking application built with Flutter and Firebase. The goal of the app is to make workout logging simple, flexible, and consistent while also encouraging motivation through social interaction and challenges.

The app allows users to create accounts, log workouts with detailed exercise information, and manage their workout history through full CRUD functionality. Users can view their progress through a dashboard that updates in real time based on saved workout data. Optional social features allow workouts to be shared, liked, and commented on, and challenges provide an additional layer of engaging fun.

BeastMode is built using a layered architecture that separates the user interface, data models, and backend services. The frontend is developed in Flutter, while Firebase Authentication handles user accounts and Firestore stores workouts, challenges, and social data. Firebase Storage is used for workout photos, and real-time updates ensure the interface stays in sync with the database.

Security is enforced through Firebase Authentication and Firestore security rules, which restrict data access to authorized users and ensure that users can only modify their own data. Input validation and error handling are implemented throughout the app to prevent invalid writes and provide clear feedback to the user.

Testing was done continuously during development using mock data and test accounts. Core functionality such as authentication, workout CRUD operations, dashboard calculations, challenge progress tracking, and social interactions were all verified. Bugs were tracked and resolved through GitHub commits and team communication.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
