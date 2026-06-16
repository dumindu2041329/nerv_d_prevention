import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/alert.dart';
import '../../../domain/repositories/alert_repository.dart';

part 'alert_event.dart';
part 'alert_state.dart';

class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final AlertRepository _repository;

  AlertBloc({required AlertRepository repository})
      : _repository = repository,
        super(AlertInitial()) {
    on<LoadAlerts>(_onLoad);
    on<RefreshAlerts>(_onRefresh);
  }

  Future<void> _onLoad(LoadAlerts event, Emitter<AlertState> emit) async {
    emit(AlertLoading());
    try {
      final alerts = await _repository.getActiveAlerts();
      emit(
        AlertLoaded(
          alerts: _sort(alerts),
          lastFetched: _repository.lastFetched,
          isStaleCache: !_repository.hasFreshCache,
        ),
      );
    } catch (e) {
      emit(AlertError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshAlerts event,
    Emitter<AlertState> emit,
  ) async {
    // Keep showing the previous list while refreshing; never blank
    // the UI just because the network was slow.
    try {
      await _repository.refresh();
      final alerts = await _repository.getActiveAlerts();
      emit(
        AlertLoaded(
          alerts: _sort(alerts),
          lastFetched: _repository.lastFetched,
          isStaleCache: !_repository.hasFreshCache,
        ),
      );
    } catch (e) {
      emit(AlertError(e.toString()));
    }
  }

  /// Most severe first. [SeverityLevel.index] puts critical at 0, so
  /// `compareTo` ascending gives the desired order.
  static List<Alert> _sort(List<Alert> alerts) {
    final copy = [...alerts];
    copy.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return copy;
  }
}
