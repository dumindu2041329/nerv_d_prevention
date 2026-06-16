part of 'alert_bloc.dart';

abstract class AlertEvent extends Equatable {
  const AlertEvent();
  @override
  List<Object?> get props => const [];
}

/// Load alerts for the first time on screen mount. Reads from cache
/// if fresh, otherwise triggers an upstream fetch.
class LoadAlerts extends AlertEvent {
  const LoadAlerts();
}

/// User-initiated refresh (pull-to-refresh). Always hits the upstream.
class RefreshAlerts extends AlertEvent {
  const RefreshAlerts();
}
