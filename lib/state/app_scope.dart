import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Makes [AppState] available to the widget tree and rebuilds dependents when
/// it changes. Must sit above MaterialApp so that dialogs and bottom sheets can
/// reach it too.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState app,
    required super.child,
  }) : super(notifier: app);

  static AppState of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
