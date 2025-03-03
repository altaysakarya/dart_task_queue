import 'package:dart_task_queue/dart_task_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskQueue Tests', () {
    late TaskQueue queue;

    setUp(() {
      queue = Queue.create(TestTaskQueue());
    });

    tearDown(() {
      Queue.deleteAll();
    });

    test('Add task and verify state transitions', () async {
      final states = <TaskState>[];

      final task = queue.addTask(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return;
      });

      task.stateStream.listen((state) {
        states.add(state);
      });

      await Future.delayed(Duration(milliseconds: 200));

      expect(states, [TaskState.running, TaskState.completed]);
    });

    test('Remove Task', () async {
      final task = queue.addTask(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return;
      });

      await Future.delayed(Duration(milliseconds: 50));
      queue.removeTask(task);

      await Future.delayed(Duration(milliseconds: 100));
      expect(task, isNot(queue.checkTask(task)));
    });

    test('Task timeout', () async {
      queue.timeout = 1;

      final task = queue.addTask(() async {
        await Future.delayed(Duration(seconds: 2));
      });

      await Future.delayed(Duration(seconds: 2));
      expect(task.state, TaskState.failed);
    });
  });
}

class TestTaskQueue extends TaskQueue {}
