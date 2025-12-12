# Performance Optimization Guide

This document outlines the performance optimizations implemented in the Beast Mode app and provides guidance for profiling and further improvements.

## Optimizations Implemented

### 1. Image Loading and Caching ✅
- **Added `cached_network_image` package** for efficient image caching
- **Replaced `NetworkImage` and `Image.network`** with `CachedNetworkImage`
- **Benefits:**
  - Images are cached locally, reducing network requests
  - Faster image loading on subsequent views
  - Reduced bandwidth usage
  - Better user experience with placeholder and error widgets

**Files Modified:**
- `lib/screens/feed_screen.dart` - Profile images now use cached images
- `lib/screens/photo_journal_screen.dart` - Photo grid uses cached images with memory optimization

### 2. Memory Leak Fixes ✅
- **Firebase Messaging Listeners:** Properly disposed in `main.dart`
- **TextEditingController and ValueNotifiers:** Properly disposed in comments dialog
- **Stream Subscriptions:** Added proper cancellation in feed screen

**Files Modified:**
- `lib/main.dart` - Added dispose method for Firebase Messaging subscriptions
- `lib/screens/feed_screen.dart` - Refactored comments dialog to use StatefulWidget with proper disposal

### 3. Firestore Query Optimization ✅
- **Reduced nested StreamBuilders:** Removed per-item comment count streams
- **Pagination:** Implemented pagination for feed (20 items per page)
- **Comment Count Caching:** Store comment count in workout document to avoid subcollection queries

**Files Modified:**
- `lib/screens/feed_screen.dart` - Optimized feed loading with pagination and reduced queries

### 4. App Startup Optimization ✅
- Firebase initialization is already optimized (required before runApp)
- Consider lazy loading non-critical features in future updates

## Profiling with Flutter DevTools

### Setup
1. Run your app in profile mode:
   ```bash
   flutter run --profile
   ```

2. Open Flutter DevTools:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

3. Connect to your running app and navigate to:
   - **Performance** tab for frame rendering analysis
   - **Memory** tab for memory leak detection
   - **Network** tab for API call analysis

### Key Metrics to Monitor

#### Performance Tab
- **Frame Rendering Time:** Should be < 16ms for 60fps
- **Jank:** Look for frames taking > 16ms
- **Widget Build Times:** Identify slow widgets

#### Memory Tab
- **Memory Usage:** Monitor for steady increases (potential leaks)
- **Object Counts:** Watch for unbounded growth
- **Heap Snapshots:** Compare before/after navigation

#### Network Tab
- **Request Count:** Minimize redundant Firestore queries
- **Response Times:** Monitor Firestore query performance
- **Data Transfer:** Optimize payload sizes

### Common Performance Issues to Check

1. **Excessive Rebuilds**
   - Use `const` constructors where possible
   - Implement `shouldRebuild` in custom widgets
   - Use `ValueListenableBuilder` for specific updates

2. **Large Lists**
   - Use `ListView.builder` instead of `ListView`
   - Implement pagination (already done for feed)
   - Consider `ListView.separated` for better performance

3. **Image Loading**
   - Use `cached_network_image` (already implemented)
   - Set appropriate `memCacheWidth` and `memCacheHeight`
   - Use placeholder widgets

4. **Firestore Queries**
   - Limit query results with `.limit()`
   - Use pagination for large datasets
   - Cache frequently accessed data
   - Avoid nested real-time listeners

## Memory Leak Detection

### Using DevTools
1. Take a heap snapshot before navigation
2. Navigate to a screen and back
3. Take another heap snapshot
4. Compare snapshots - look for:
   - Controllers not being disposed
   - Stream subscriptions not cancelled
   - Listeners not removed

### Manual Checks
- All `TextEditingController` instances are disposed
- All `StreamSubscription` instances are cancelled
- All `ValueNotifier` instances are disposed
- All `AnimationController` instances are disposed
- All `FocusNode` instances are disposed

## Further Optimization Opportunities

### Short Term
1. **Implement image compression** before upload
2. **Add request debouncing** for search/filter operations
3. **Cache user profile data** locally
4. **Optimize Firestore indexes** for common queries

### Long Term
1. **Implement offline support** with local caching
2. **Add background sync** for data updates
3. **Implement code splitting** for large features
4. **Add analytics** to track performance metrics
5. **Consider using Riverpod/Provider** for better state management

## Testing Performance

### Performance Tests
Run performance tests to ensure optimizations are working:
```bash
flutter test --profile
```

### Manual Testing Checklist
- [ ] App starts quickly (< 2 seconds)
- [ ] Images load smoothly without jank
- [ ] Scrolling is smooth (60fps)
- [ ] Memory usage remains stable
- [ ] No memory leaks when navigating
- [ ] Network requests are minimized
- [ ] Pagination works correctly

## Monitoring in Production

Consider adding:
- **Firebase Performance Monitoring** for real-world metrics
- **Crashlytics** for crash reports
- **Analytics** to track user behavior and performance

## Resources

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter DevTools Documentation](https://docs.flutter.dev/tools/devtools)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
