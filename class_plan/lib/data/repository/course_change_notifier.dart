import 'dart:async';

/// 课程数据变更通知器
/// 当课程数据变化时通知所有监听者刷新
class CourseChangeNotifier {
  static final CourseChangeNotifier _instance = CourseChangeNotifier._();
  factory CourseChangeNotifier() => _instance;
  CourseChangeNotifier._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get changes => _controller.stream;

  void notify() {
    _controller.add(null);
  }
}
