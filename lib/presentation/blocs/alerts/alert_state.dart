part of 'alert_bloc.dart';

abstract class AlertState extends Equatable {
  const AlertState();
  @override
  List<Object?> get props => const [];
}

class AlertInitial extends AlertState {
  const AlertInitial();
}

class AlertLoading extends AlertState {
  const AlertLoading();
}

class AlertLoaded extends AlertState {
  final List<Alert> alerts;
  final DateTime? lastFetched;
  final bool isStaleCache;

  const AlertLoaded({
    required this.alerts,
    required this.lastFetched,
    required this.isStaleCache,
  });

  @override
  List<Object?> get props => [alerts, lastFetched, isStaleCache];
}

class AlertError extends AlertState {
  final String message;
  const AlertError(this.message);
  @override
  List<Object?> get props => [message];
}
