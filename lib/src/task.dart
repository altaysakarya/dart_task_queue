import 'dart:async';

enum TaskState { pending, running, completed, failed }

class Task<T> {
  final String id;
  final Future<T> Function() task;
  final Completer<T?> completer = Completer<T?>();
  Future<T?> get future => completer.future;

  TaskState _state;
  TaskState get state => _state;
  set state(TaskState newState) {
    if (_state == newState) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
      if (newState == TaskState.completed || newState == TaskState.failed) {
        _stateController.close();
      }
    }
  }

  final StreamController<TaskState> _stateController = StreamController<TaskState>();

  Stream<TaskState> get stateStream => _stateController.stream;

  Task(this.id, this.task) : _state = TaskState.pending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task<T> && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}