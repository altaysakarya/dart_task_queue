import 'dart:async';
import 'dart:collection' as collection;

import 'package:dart_task_queue/src/task.dart';

/// Abstract class for managing a queue of asynchronous tasks.
abstract class TaskQueue {
  // Internal queue to hold tasks.
  final collection.Queue<Task> _tasks = collection.Queue<Task>();

  // Indicates if the queue is currently processing tasks.
  bool _isRunning = false;

  /// Maximum number of tasks allowed in the queue.
  int maxQueueLength = 10;

  /// Timeout duration (in seconds) for each task execution.
  int timeout = 30;

  /// Remove all pending tasks and clears the queue.
  void dispose() {
    for (final task in _tasks) {
      task.state = TaskState.failed;
    }
    _tasks.clear();
  }

  /// Checks if a specific [task] is still pending in the queue.
  bool checkTask(Task task) {
    return _tasks.any((t) => t == task);
  }

  /// Adds a new task to the queue.
  ///
  /// Throws an [Exception] if the queue has reached its maximum capacity.
  /// Starts processing tasks if not already running.
  Task addTask(Future<dynamic> Function() task) {
    if (_tasks.length >= maxQueueLength) {
      throw Exception("Task queue is full");
    }
    final taskObject =
        Task("${task.hashCode ^ DateTime.now().microsecondsSinceEpoch}", task);
    _tasks.add(taskObject);

    if (!_isRunning) {
      _run();
    }
    return taskObject;
  }

  /// Remove a specific [task] if it is still pending in the queue.
  void removeTask(Task task) {
    _tasks.remove(task);
  }

  /// Processes tasks sequentially.
  /// Each task is executed with a timeout defined by [timeout].
  Future<void> _run() async {
    if (_isRunning) return;

    _isRunning = true;
    while (_tasks.isNotEmpty) {
      final task = _tasks.removeFirst();
      if (task.state != TaskState.pending) continue;

      task.state = TaskState.running;
      try {
        await task.task().timeout(Duration(seconds: timeout));
        task.state = TaskState.completed;
      } catch (_) {
        task.state = TaskState.failed;
      }
    }
    _isRunning = false;
  }
}

/// Singleton manager for handling TaskQueue instances.
class TaskQueueManager {
  // Private constructor for singleton pattern.
  TaskQueueManager._();

  /// The single instance of TaskQueueManager.
  static final TaskQueueManager instance = TaskQueueManager._();

  /// Internal list holding all registered TaskQueue instances.
  final List<TaskQueue> _taskQueues = [];

  /// Checks if a TaskQueue of type [S] is already registered.
  bool isRegistered<S extends TaskQueue>() =>
      _taskQueues.any((queue) => queue is S);

  /// Creates and registers a new TaskQueue of type [S].
  ///
  /// Throws an exception if a TaskQueue of this type already exists.
  S create<S extends TaskQueue>(S taskQueue) {
    if (isRegistered<S>()) {
      throw TaskQueueAlreadyExists(
          "TaskQueue of type ${S.toString()} already exists.");
    }
    _taskQueues.add(taskQueue);
    return taskQueue;
  }

  /// Retrieves a registered TaskQueue of type [S].
  ///
  /// Throws an exception if not found.
  S get<S extends TaskQueue>() {
    return _taskQueues.firstWhere(
      (queue) => queue is S,
      orElse: () => throw TaskQueueNotFoundException(
          "TaskQueue of type ${S.toString()} not found."),
    ) as S;
  }

  /// Returns an existing TaskQueue of type [S] or creates one using [taskQueueFactory].
  S getOrCreate<S extends TaskQueue>(S taskQueueFactory) {
    try {
      return get<S>();
    } catch (_) {
      return create(taskQueueFactory);
    }
  }

  /// Deletes a registered TaskQueue of type [S] and disposes its resources.
  void delete<S extends TaskQueue>() {
    _taskQueues.removeWhere((queue) {
      if (queue is S) {
        queue.dispose();
        return true;
      }
      return false;
    });
  }

  /// Deletes all registered TaskQueues and disposes their resources.
  void deleteAll() {
    for (var queue in _taskQueues) {
      queue.dispose();
    }
    _taskQueues.clear();
  }
}

TaskQueueManager get Queue => TaskQueueManager.instance;

class TaskQueueAlreadyExists implements Exception {
  final String message;

  TaskQueueAlreadyExists(this.message);

  @override
  String toString() => message;
}

class TaskQueueNotFoundException implements Exception {
  final String message;

  TaskQueueNotFoundException(this.message);

  @override
  String toString() => message;
}
