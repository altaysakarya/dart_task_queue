import 'dart:async';
import 'dart:collection' as collection;

import 'package:dart_task_queue/src/task.dart';

abstract class TaskQueue {
  final collection.Queue<Task<dynamic>> _tasks =
      collection.Queue<Task<dynamic>>();
  bool _isRunning = false;
  int maxQueueLength = 10;
  int timeout = 30;

  Function() get _noop => () {};
  Function(Task) get _noopt => (_) {};

  Function() get onTaskQueueStarted => _noop;
  Function() get onTaskQueueEnded => _noop;
  Function(Task) get onPerTaskStarted => _noopt;
  Function(Task) get onPerTaskEnded => _noopt;

  void dispose() {
    for (final task in _tasks) {
      if (task.state == TaskState.running) {
        task.completer
            .completeError(Exception("Task queue disposed before completion"));
      }
      task.state = TaskState.failed;
    }
    _tasks.clear();
  }

  bool checkTask(Task task) {
    return _tasks.any((t) => t == task);
  }

  Task<T> addTask<T>(Future<T> Function() task) {
    if (_tasks.length >= maxQueueLength) {
      throw Exception("Task queue is full");
    }
    final taskObject = Task<T>(
        "${task.hashCode ^ DateTime.now().microsecondsSinceEpoch}", task);
    _tasks.add(taskObject);

    if (!_isRunning) {
      _run();
    }
    return taskObject;
  }

  void removeTask(Task task) {
    if (task.state == TaskState.running) return;
    _tasks.remove(task);
  }

  Future<void> _run() async {
    if (_isRunning) return;
    onTaskQueueStarted.call();
    _isRunning = true;
    while (_tasks.isNotEmpty) {
      final task = _tasks.removeFirst();
      if (task.state != TaskState.pending) continue;

      task.state = TaskState.running;
      onPerTaskStarted.call(task);
      try {
        dynamic p = await task.task().timeout(Duration(seconds: timeout));
        task.state = TaskState.completed;
        task.completer.complete(p);
      } catch (e, stackTrace) {
        task.state = TaskState.failed;
        task.completer.completeError(e, stackTrace);
      }
      onPerTaskEnded.call(task);
    }
    onTaskQueueEnded.call();
    _isRunning = false;
  }
}

/// Singleton class for managing TaskQueues.
class TaskQueueManager {
  TaskQueueManager._();

  static final TaskQueueManager instance = TaskQueueManager._();

  final List<TaskQueue> _taskQueues = [];

  /// Checks if a TaskQueue of type [S] is registered.
  bool isRegistered<S extends TaskQueue>() =>
      _taskQueues.any((queue) => queue is S);

  /// Creates and registers a new TaskQueue of type [S].
  /// Throws [TaskQueueAlreadyExists] if one already exists.
  S create<S extends TaskQueue>(S taskQueue) {
    if (isRegistered<S>()) {
      throw TaskQueueAlreadyExists(
          "TaskQueue of type ${S.toString()} already exists.");
    }
    _taskQueues.add(taskQueue);
    return taskQueue;
  }

  /// Retrieves the registered TaskQueue of type [S].
  /// Throws [TaskQueueNotFoundException] if not found.
  S get<S extends TaskQueue>() {
    return _taskQueues.firstWhere(
      (queue) => queue is S,
      orElse: () => throw TaskQueueNotFoundException(
          "TaskQueue of type ${S.toString()} not found."),
    ) as S;
  }

  /// Returns the TaskQueue of type [S] if it exists,
  /// otherwise creates one using the provided instance.
  S getOrCreate<S extends TaskQueue>(S taskQueue) {
    return isRegistered<S>() ? get<S>() : create(taskQueue);
  }

  /// Deletes the TaskQueue of type [S] and releases its resources.
  void delete<S extends TaskQueue>() {
    for (var i = 0; i < _taskQueues.length; i++) {
      if (_taskQueues[i] is S) {
        _taskQueues[i].dispose();
        _taskQueues.removeAt(i);
        break;
      }
    }
  }

  /// Deletes all TaskQueues.
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
