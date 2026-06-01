import 'package:flutter_slideable_cell/flutter_slideable_cell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

/// 复用的小型 cell 构造函数（保持 widget 形状一致以便 element diff 稳定）。
/// Reusable cell builder; keeps widget shape stable for predictable element diff.
Widget _buildCell({
  required SlideableCellController controller,
  required ValueKey<String> key,
  required String label,
}) {
  return SlideableCellView(
    key: key,
    controller: controller,
    duration: const Duration(milliseconds: 50),
    trailingActions: const [
      SizedBox(
        width: 60,
        height: 50,
        child: ColoredBox(color: Color(0xFFFF0000)),
      ),
    ],
    child: SizedBox(
      height: 50,
      width: 200,
      child: Text(label),
    ),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 320,
        height: 400,
        child: child,
      ),
    ),
  );
}

void main() {
  test('controller returns closed status by default', () {
    final controller = SlideableCellController();
    expect(
      controller.statusOf(const ValueKey('unknown')),
      SlideableCellStatus.closed,
    );
    expect(controller.isOpen(const ValueKey('unknown')), isFalse);
    expect(controller.statuses, isEmpty);
  });

  test('operations on unknown key do not throw', () async {
    final controller = SlideableCellController();
    await controller.openLeading(const ValueKey('missing'));
    await controller.openTrailing(const ValueKey('missing'));
    await controller.openLeadingFullExpand(const ValueKey('missing'));
    await controller.openTrailingFullExpand(const ValueKey('missing'));
    await controller.closeCell(const ValueKey('missing'));
    await controller.closeAllCells();
    expect(controller.statuses, isEmpty);
  });

  testWidgets('controller drives a single cell open/close', (tester) async {
    final controller = SlideableCellController();
    const key = ValueKey<String>('only');

    await tester.pumpWidget(
      _wrap(_buildCell(controller: controller, key: key, label: 'only')),
    );
    await tester.pumpAndSettle();

    expect(controller.isOpen(key), isFalse);

    final openFuture = controller.openTrailing(key);
    await tester.pumpAndSettle();
    await openFuture;
    expect(controller.isOpen(key), isTrue);
    expect(
      controller.statusOf(key),
      SlideableCellStatus.trailingOpen,
    );

    final closeFuture = controller.closeCell(key);
    await tester.pumpAndSettle();
    await closeFuture;
    expect(controller.isOpen(key), isFalse);
    expect(controller.statuses, hasLength(1));
  });

  testWidgets(
    'duplicate ValueKey closes the previous entry instead of leaking it',
    (tester) async {
      final controller = SlideableCellController();
      const key = ValueKey<String>('dup');

      // 第一个 cell 先注册并打开。
      // First cell registers and opens.
      await tester.pumpWidget(
        _wrap(_buildCell(controller: controller, key: key, label: 'first')),
      );
      await tester.pumpAndSettle();

      final openFuture = controller.openTrailing(key);
      await tester.pumpAndSettle();
      await openFuture;
      expect(controller.isOpen(key), isTrue,
          reason: 'first cell should be open after openTrailing');

      // 此时再 mount 一个使用相同 ValueKey 的 cell。
      // 通过 Container 包一层，避免两个 SlideableCellView 直接成为
      // sibling 触发 Flutter 的 duplicate-key 调试断言。
      // Mount a second cell sharing the same ValueKey. Wrapping each in a
      // Container avoids putting the two SlideableCellView nodes as direct
      // siblings, which would trip Flutter's duplicate-key debug assertion.
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              SizedBox(
                height: 60,
                child: _buildCell(
                  controller: controller,
                  key: key,
                  label: 'first',
                ),
              ),
              SizedBox(
                height: 60,
                child: _buildCell(
                  controller: controller,
                  key: key,
                  label: 'second',
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 重复注册触发后：
      // - controller 的映射已替换为新 cell；
      // - 旧 cell 收到了来自 controller 的 close()，避免出现"屏幕上还开着、
      //   但 controller 里已经丢了引用、无法关闭"的悬挂状态。
      // After the duplicate registration:
      // - controller mapping points at the new cell;
      // - the old cell received a close() from the controller, so we never
      //   end up with a visually-open cell orphaned from the controller.
      expect(controller.statuses, hasLength(1));
      expect(controller.isOpen(key), isFalse,
          reason:
              'after duplicate registration, the live cell should be closed (not leaked open)');

      // 通过 controller 仍能正常控制新 cell。
      // Controller can still drive the new cell normally.
      final reopen = controller.openTrailing(key);
      await tester.pumpAndSettle();
      await reopen;
      expect(controller.isOpen(key), isTrue);
    },
  );

  testWidgets(
    'late dispose of replaced entry does not break the live registration',
    (tester) async {
      final controller = SlideableCellController();
      const key = ValueKey<String>('dup');

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              SizedBox(
                height: 60,
                child: _buildCell(
                  controller: controller,
                  key: key,
                  label: 'first',
                ),
              ),
              SizedBox(
                height: 60,
                child: _buildCell(
                  controller: controller,
                  key: key,
                  label: 'second',
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 重复注册后，活跃 entry 是第二个 cell。
      // After duplicate registration the live entry is the second cell.
      expect(controller.statuses, hasLength(1));

      // 把第一个 cell 从树里移除，让被替换的旧 entry 触发 dispose -> _unregister。
      // 由于 _unregister 用 identical 校验，新 entry 的注册不应被误删。
      // Remove the first cell so the replaced old entry's dispose -> _unregister
      // fires. Identity-checked _unregister must keep the live mapping intact.
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 60,
            child: _buildCell(
              controller: controller,
              key: key,
              label: 'second',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.statuses, hasLength(1),
          reason:
              'live entry must survive the late unregister of the replaced one');

      final openFuture = controller.openTrailing(key);
      await tester.pumpAndSettle();
      await openFuture;
      expect(controller.isOpen(key), isTrue);
    },
  );
}
