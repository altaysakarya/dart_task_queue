// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

enum TaskState { pending, running, completed, failed }

class Task<T> {
  final String id;
  final Future<T> Function() task;
  final Function(T)? onCompleted;
  final Completer<T> completer = Completer<T>();
  Future<T> get future => completer.future;

  TaskState _state;
  TaskState get state => _state;
  set state(TaskState newState) {
    _state = newState;
    _stateController.add(newState);
    if (newState == TaskState.completed || newState == TaskState.failed) {
      completer.complete();
      _stateController.close();
    }
  }

  final StreamController<TaskState> _stateController =
      StreamController<TaskState>();

  Stream<TaskState> get stateStream => _stateController.stream;

  Task(this.id, this.task, this.onCompleted) : _state = TaskState.pending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task<T> && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

extension TaskStateX on TaskState {
  bool get isPending => this == TaskState.pending;
  bool get isRunning => this == TaskState.running;
  bool get isCompleted => this == TaskState.completed;
  bool get isFailed => this == TaskState.failed;
}
