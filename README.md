# Dart Task Queue

A powerful and flexible task queue implementation for Dart applications, providing efficient management of asynchronous tasks with status tracking and timeout capabilities.

## Features

- ✨ Queue-based task management
- 🔄 Task status tracking (pending, running, completed, cancelled, failed)
- ⏱️ Configurable timeout for tasks
- 🎯 Maximum queue length control
- 📊 Task state change notifications
- 🔍 Stream-based state monitoring
- 🎛️ Singleton queue manager for multiple queue instances

## Installation

```bash
dart pub add dart_task_queue
```

## Usage

### Basic Usage

```dart
// Create a custom task queue
class MyTaskQueue extends TaskQueue {}

// Get or create a queue instance
final myQueue = Queue.getOrCreate(MyTaskQueue());

// Add a task
final task = myQueue.addTask(() async {
    // Your async task here
    await Future.delayed(Duration(seconds: 1));
});

// Monitor task state changes
task.stateStream.listen((state) {
    print('Task state changed to: $state');
});
```

### Task Queue Manager

```dart
// Create multiple queue types
class DownloadQueue extends TaskQueue {}
class UploadQueue extends TaskQueue {}

// Get specific queue instances
final downloadQueue = Queue.getOrCreate(DownloadQueue());
final uploadQueue = Queue.getOrCreate(UploadQueue());

// Clean up when done
Queue.delete<DownloadQueue>();
Queue.deleteAll(); // Remove all queues
```

## Configuration

```dart
class MyTaskQueue extends TaskQueue {
    MyTaskQueue() {
        maxQueueLength = 20; // Set maximum queue size
        timeout = 60; // Set timeout in seconds
    }
}
```