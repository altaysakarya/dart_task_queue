// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

enum TaskState { pending, running, completed, failed }

class Task {
  final String id;
  final Future<void> Function() task;

  TaskState _state;
  TaskState get state => _state;
  set state(TaskState newState) {
    _state = newState;
    _stateController.add(newState);
    if (newState == TaskState.completed || newState == TaskState.failed) {
      _stateController.close();
    }
  }

  final StreamController<TaskState> _stateController =
      StreamController<TaskState>();

  Stream<TaskState> get stateStream => _stateController.stream;

  Task(this.id, this.task) : _state = TaskState.pending;

  @override
  bool operator ==(covariant Task other) {
    if (identical(this, other)) return true;

    return other.id == id && other.task == task;
  }

  @override
  int get hashCode => id.hashCode ^ task.hashCode;
}
