# Notification System Guide

This document explains how to use the notification system in the Firefly app for communication between views without direct dependencies.

## Overview

The notification system allows views to:
- **Post notifications** when actions occur (e.g., transaction deleted)
- **Listen for notifications** from other views to trigger updates
- **Stay independent** without needing to pass data or callbacks

## Notification Constants

All notifications are defined in `Firefly/Helpers/NotificationConstants.swift`:

```swift
struct AppNotifications {
  static let transactionDeleted = Notification.Name("transactionDeleted")
  static let transactionCreated = Notification.Name("transactionCreated")
  static let transactionUpdated = Notification.Name("transactionUpdated")
}
```

## How to Post a Notification

When an action completes successfully, post a notification:

```swift
// Example: In TransactionDetail.swift after deletion succeeds
NotificationCenter.default.post(
    name: AppNotifications.transactionDeleted,
    object: nil
)
```

You can also pass data via `userInfo`:

```swift
NotificationCenter.default.post(
    name: AppNotifications.transactionDeleted,
    object: nil,
    userInfo: ["transactionID": "123"]
)
```

## How to Listen for Notifications

In any view, add a notification listener in the `setupNotificationListeners()` method:

### Example: TransactionsView

```swift
private func setupNotificationListeners() {
    NotificationCenter.default.addObserver(
        forName: AppNotifications.transactionDeleted,
        object: nil,
        queue: .main
    ) { _ in
        // Silent refresh when a transaction is deleted
        Task {
            await transactions.fetchTransactions()
        }
    }
}
```

Call this in your view's body:

```swift
var body: some View {
    let _ = setupNotificationListeners()
    // rest of your view...
}
```

### Example: With userInfo

```swift
NotificationCenter.default.addObserver(
    forName: AppNotifications.transactionDeleted,
    object: nil,
    queue: .main
) { notification in
    if let transactionID = notification.userInfo?["transactionID"] as? String {
        print("Transaction \(transactionID) was deleted")
        // Handle the specific transaction
    }
}
```

## Current Implementation

### Notifications Defined
- **transactionDeleted** - Posted when a transaction is successfully deleted
- **transactionCreated** - Posted when a transaction is successfully created
- **transactionUpdated** - Posted when a transaction is successfully updated

### Views Listening
- **TransactionsView** - Listens for all three transaction notifications and refreshes silently

### Views Posting
- **TransactionDetail** - Posts `transactionDeleted` after successful deletion

## Adding a New Notification

1. **Define** the notification in `NotificationConstants.swift`:
   ```swift
   static let myNewEvent = Notification.Name("myNewEvent")
   ```

2. **Post** it from the appropriate view/helper when the event occurs:
   ```swift
   NotificationCenter.default.post(name: AppNotifications.myNewEvent, object: nil)
   ```

3. **Listen** for it in views that need to react:
   ```swift
   NotificationCenter.default.addObserver(
       forName: AppNotifications.myNewEvent,
       object: nil,
       queue: .main
   ) { _ in
       // Handle the event
   }
   ```

## Best Practices

✅ **DO:**
- Use for events that multiple views might care about
- Post notifications after async operations complete successfully
- Listen on `.main` queue to ensure UI updates happen on the main thread
- Keep notification names descriptive (past tense for events that happened)

❌ **DON'T:**
- Use notifications for one-to-one communication (use callbacks/bindings instead)
- Post notifications before validation/error checking
- Keep notification listeners registered after they're no longer needed (use `removeObserver` in `deinit` if needed for long-lived listeners)
- Pass large objects in `userInfo` (keep it lightweight)

## Similar Pattern: Safari Notifications

The app also uses notifications for Safari errors (see `SafariHelper.swift`):
- `SafariErrorNotification` - Posted when Safari URL opening fails
- `SafariSuccessNotification` - Posted when Safari opens successfully

These are listened to by `AlertViewModel` to show toast messages.

## Thread Safety

Always observe on `.main` queue for UI-related notifications:

```swift
NotificationCenter.default.addObserver(
    forName: AppNotifications.transactionDeleted,
    object: nil,
    queue: .main  // ← Important for UI updates
) { _ in
    // This closure will run on the main thread
}
```
